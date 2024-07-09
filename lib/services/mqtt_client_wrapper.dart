import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_3/models/user_credentials.dart';
import 'package:flutter_3/utils/constants.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

typedef MqttDataCallback = void Function(Map<String, dynamic> data);

class MQTTClientWrapper {
  late MqttServerClient client;
  late MqttDataCallback onDataReceived;
  Timer? _statusTimer;

  Set<String> subscribedTopics = {};

  void _startStatusTimer() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      print('MQTT Connection Status: ${client.connectionStatus}');
    });
  }

  Future<void> prepareMqttClient() async {
    try {
      final credentials = UserCredentials();
      final username = credentials.username;
      final password = credentials.password;
      _setupMqttClient(username);
      await _connectClient(username, password);

      setupMessageListener();
      _startStatusTimer();
    } catch (e, stackTrace) {
      print('Error in prepareMqttClient: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
      disconnect();
    }
  }

  Future<void> _connectClient(String username, String password) async {
    try {
      print('Connecting to MQTT broker...');
      await client.connect(username, password);
      print('Connected to MQTT broker');
    } catch (e, stackTrace) {
      print('Error in _connectClient: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
      disconnect();
    }
  }

  Future<void> disconnect() async {
    try {
      print('Disconnecting MQTT client...');
      client.disconnect();
      print('MQTT client disconnected');
    } catch (e, stackTrace) {
      print('Error in disconnect: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
    }
  }

  void _setupMqttClient(String username) {
    try {
      client = MqttServerClient.withPort(
        Constants.mqttBrokerUrl,
        username,
        1883,
      );
      client.secure = false;
      client.securityContext = SecurityContext.defaultContext;
      client.keepAlivePeriod = 20;
      client.autoReconnect = true;
      client.onDisconnected = _onDisconnected;
      client.onConnected = _onConnected;
      client.onSubscribed = _onSubscribed;
    } catch (e, stackTrace) {
      print('Error in _setupMqttClient: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
    }
  }

  void subscribeToTopic(String topicName) {
    try {
      client.subscribe(topicName, MqttQos.atLeastOnce);
      print('Subscribed to topic: $topicName');
      subscribedTopics.add(topicName);
    } catch (e, stackTrace) {
      print('Error in subscribeToTopic: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
    }
  }

  void subscribeToMultipleTopics(List<String> topics) {
    try {
      topics.forEach(subscribeToTopic);
    } catch (e, stackTrace) {
      print('Error in subscribeToMultipleTopics: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
    }
  }

  void setupMessageListener() {
    try {
      client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final message =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        // Parse message to Map<String, dynamic>
        final Map<String, dynamic> data = parseMessage(message);

        // Add the topic to the data map
        data['topic'] = c[0].topic;

        // Invoke callback with parsed data
        onDataReceived(data);
      });
    } catch (e, stackTrace) {
      print('Error in setupMessageListener: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
    }
  }

  void unsubscribeFromTopic(String topic) {
    try {
      print('Unsubscribing from the $topic topic');
      client.unsubscribe(topic);
      subscribedTopics.remove(topic);
    } catch (e, stackTrace) {
      print('Error in unsubscribeFromTopic: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
    }
  }

  void unsubscribeFromMultipleTopics(List<String> topics) {
    try {
      topics.forEach(unsubscribeFromTopic);
    } catch (e, stackTrace) {
      print('Error in unsubscribeFromMultipleTopics: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
    }
  }

  void publishMessage(String topic, String message) {
    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);

      print('Publishing message "$message" to topic $topic');
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    } catch (e, stackTrace) {
      print('Error in publishMessage: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
    }
  }

  dynamic parseMessage(String message) {
    try {
      // Attempt to parse the message as JSON
      return json.decode(message);
    } catch (e, stackTrace) {
      print('Error in parseMessage: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
      return message; // Return the original message on error
    }
  }

  void _onSubscribed(String topic) {
    try {
      print('Subscription confirmed for topic $topic');
    } catch (e, stackTrace) {
      print('Error in _onSubscribed: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
    }
  }

  void _onDisconnected() {
    try {
      print('Disconnected from MQTT broker');
      // Attempt to reconnect if not already disconnected
      if (client.connectionStatus?.state != MqttConnectionState.disconnected &&
          client.connectionStatus?.state != MqttConnectionState.disconnecting) {
        client.connect();
      }
    } catch (e, stackTrace) {
      print('Error in _onDisconnected: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
    }
  }

  void _onConnected() {
    try {
      print('Connected to MQTT broker');
    } catch (e, stackTrace) {
      print('Error in _onConnected: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
    }
  }

  void logout() {
    try {
      // Disconnect MQTT client
      disconnect();

      // Stop auto reconnection
      client.autoReconnect = false;

      // Clear status timer
      _statusTimer?.cancel();

      // Clear subscribed topics
      subscribedTopics.clear();
    } catch (e, stackTrace) {
      print('Error in logout: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
    }
  }
}
