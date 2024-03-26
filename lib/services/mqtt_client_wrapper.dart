import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class UserCredentials {
  late String username;
  late String password;

  // Singleton pattern to ensure only one instance of UserCredentials
  static final UserCredentials _instance = UserCredentials._internal();

  factory UserCredentials() {
    return _instance;
  }

  UserCredentials._internal();

  void setUserCredentials(String username, String password) {
    this.username = username;
    this.password = password;
  }

  Future<void> clearUserCredentials() async {
    this.username = '';
    this.password = '';
  }
}

enum MqttCurrentConnectionState {
  IDLE,
  CONNECTING,
  CONNECTED,
  DISCONNECTED,
  ERROR_WHEN_CONNECTING,
  LOGGED_OUT,
}

enum MqttSubscriptionState { IDLE, SUBSCRIBED }

typedef void MqttDataCallback(Map<String, dynamic> data);

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
    _setupMqttClient();
    await _connectClient(username, password);
    setupMessageListener();
  }

  Future<void> _connectClient(String username, String password) async {
    try {
      print('client connecting....');
      connectionState = MqttCurrentConnectionState.CONNECTING;
      await client.connect(username, password);
    } on Exception catch (e) {
      print('client exception - $e');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
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

  void _setupMqttClient() {
    client = MqttServerClient.withPort(
        'df29475dfed14680a1a57a1c8e98b400.s2.eu.hivemq.cloud',
        'test-mobile-app',
        8883);
    client.secure = true;
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
    client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }

  void _onSubscribed(String topic) {
    print('Subscription confirmed for topic $topic');
    subscriptionState = MqttSubscriptionState.SUBSCRIBED;
  }

  void _onDisconnected() {
    final credentials = UserCredentials();
    final username = credentials.username;
    final password = credentials.password;

    if (connectionState != MqttCurrentConnectionState.LOGGED_OUT) {
      print('Attempting to reconnect...');
      connectionState = MqttCurrentConnectionState.CONNECTING;

      _connectClient(username, password);
    } else {
      print('User logged out, skipping reconnection attempt.');
    }
  }

  void _onConnected() {
    connectionState = MqttCurrentConnectionState.CONNECTED;
    print('OnConnected client callback - Client connection was successful');
  }
}
