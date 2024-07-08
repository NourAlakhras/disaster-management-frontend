import 'dart:convert';
import 'dart:io';
import 'package:flutter_3/models/user_credentials.dart';
import 'package:flutter_3/utils/constants.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter_3/utils/enums.dart';


typedef MqttDataCallback = void Function(Map<String, dynamic> data);

class MQTTClientWrapper {
  late MqttServerClient client;
  MqttCurrentConnectionState connectionState = MqttCurrentConnectionState.IDLE;
  MqttSubscriptionState subscriptionState = MqttSubscriptionState.IDLE;
  late MqttDataCallback onDataReceived;
  Set<String> subscribedTopics = {};

  Future<void> prepareMqttClient() async {
    final credentials = UserCredentials();
    final username = credentials.username;
    final password = credentials.password;
    _setupMqttClient(username);
    await _connectClient(username, password);
    setupMessageListener();
  }

  Future<void> _connectClient(String username, String password) async {
    try {
      print('Connecting to MQTT broker...');
      print('Hostname: ${client.server}');
      print('Port: ${client.port}');
      connectionState = MqttCurrentConnectionState.CONNECTING;
      await client.connect(username, password);
      print('Connected to MQTT broker');
    } on Exception catch (e) {
      print('Failed to connect to MQTT broker: $e');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
      return;
    }
    // Check if already connected or connecting
    if (client.connectionStatus?.state == MqttConnectionState.connected ||
        connectionState == MqttCurrentConnectionState.CONNECTING) {
      print('Already connected or connecting, skipping connection attempt.');
      return;
    }

    try {
      print('client connecting....');
      connectionState = MqttCurrentConnectionState.CONNECTING;
      await client.connect(username, password);
    } on Exception catch (e) {
      print('client exception - $e');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
      return;
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      connectionState = MqttCurrentConnectionState.CONNECTED;
      print('client connected');
    } else {
      print(
          'ERROR client connection failed - disconnecting, status is ${client.connectionStatus}');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
    }
  }

  Future<void> disconnect() async {
    print('Disconnecting MQTT client...');
    client.autoReconnect = false; // Disable auto-reconnect
    client.disconnect();
    print('MQTT client disconnected');
    connectionState = MqttCurrentConnectionState.DISCONNECTED;
  }

  Future<void> logout() async {
    print('Logging out from the MQTT ...');
    if (connectionState != MqttCurrentConnectionState.LOGGED_OUT) {
      connectionState = MqttCurrentConnectionState.LOGGED_OUT;
      await disconnect();
    }
  }

  void _setupMqttClient(String username) {
    client = MqttServerClient.withPort(
        Constants.mqttBrokerUrl,
        username,
        1883);
    print('setup');
    client.secure = false;
    client.securityContext = SecurityContext.defaultContext;
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
  }

  void subscribeToTopic(String topicName) {
    print('Subscribing to the $topicName topic');
    client.subscribe(topicName, MqttQos.atMostOnce);
  }

  void subscribeToMultipleTopics(List<String> topics) {
    topics.forEach(subscribeToTopic);
  }

  void setupMessageListener() {
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final message =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      // Print the name of the topic
      print('Received message from topic: ${c[0].topic}');
      print(message);

      // Parse message to Map<String, dynamic>
      final Map<String, dynamic> data = parseMessage(message);

      // Add the topic to the data map
      data['topic'] = c[0].topic;

      // Invoke callback with parsed data
      onDataReceived(data);
    });
  }

  void unsubscribeFromMultipleTopics(List<String> topics) {
    topics.forEach(unsubscribeFromTopic);
  }

  void unsubscribeFromTopic(String topic) {
    print('Unsubscribing from the $topic topic');
    client.unsubscribe(topic);
    // Remove unsubscribed topic from the subscribedTopics set
    subscribedTopics.remove(topic);
  }

  dynamic parseMessage(String message) {
    try {
      // Attempt to parse the message as JSON
      return json.decode(message);
    } catch (_) {
      // If parsing as JSON fails, return the original message
      return message;
    }
  }

  void publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    print('Publishing message "$message" to topic $topic');
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void _onSubscribed(String topic) {
    print('Subscription confirmed for topic $topic');
    subscriptionState = MqttSubscriptionState.SUBSCRIBED;
  }

  void _onDisconnected() {
    final credentials = UserCredentials();
    final username = credentials.username;
    final password = credentials.password;

    if (connectionState != MqttCurrentConnectionState.LOGGED_OUT &&
        connectionState != MqttCurrentConnectionState.CONNECTING &&
        client.connectionStatus?.state != MqttConnectionState.connected) {
      print('Attempting to reconnect...');
      connectionState = MqttCurrentConnectionState.CONNECTING;

      _connectClient(username, password);
    } else {
      print(
          'User logged out or already reconnecting, skipping reconnection attempt.');
    }
  }

  void _onConnected() {
    connectionState = MqttCurrentConnectionState.CONNECTED;
    print('OnConnected client callback - Client connection was successful');
  }

  MqttCurrentConnectionState get connectionStatus => connectionState;
}
