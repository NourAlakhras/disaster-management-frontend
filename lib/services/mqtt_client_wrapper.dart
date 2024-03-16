import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  MQTTClientWrapper newclient = new MQTTClientWrapper();
  newclient.prepareMqttClient();
}

enum MqttCurrentConnectionState {
  IDLE,
  CONNECTING,
  CONNECTED,
  DISCONNECTED,
  ERROR_WHEN_CONNECTING
}

enum MqttSubscriptionState { IDLE, SUBSCRIBED }

typedef void MqttDataCallback(Map<String, dynamic> data);

class MQTTClientWrapper {
  late MqttServerClient client;
  MqttCurrentConnectionState connectionState = MqttCurrentConnectionState.IDLE;
  MqttSubscriptionState subscriptionState = MqttSubscriptionState.IDLE;
  late MqttDataCallback onDataReceived;
  Set<String> subscribedTopics = Set<String>();


  void prepareMqttClient() async {
    _setupMqttClient();
    await _connectClient('test-mobile-app', 'Test-mobile12'); // Pass user credentials dynamically
    setupMessageListener();
  }
  Future<void> connect(String username, String password) async {
  await _setupMqttClient();
  await _connectClient(username, password);
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

  Future<void> _setupMqttClient() async {
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
  topics.forEach((topic) {
    subscribeToTopic(topic);
  });
}

void setupMessageListener() {
  client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
    final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
    var message =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    // Print the name of the topic
    print('Received message from topic: ${c[0].topic}');
    print(message);

    // Parse message to Map<String, dynamic>
    final Map<String, dynamic> data = parseMessage(message);

    // Invoke callback with parsed data
    onDataReceived(data);
  });
}


void unsubscribeFromMultipleTopics(List<String> topics) {
  topics.forEach((topic) {
    print('Unsubscribing from the $topic topic');
    client.unsubscribe(topic);
    // Remove unsubscribed topics from the subscribedTopics set
    subscribedTopics.remove(topic);
  });
}


  dynamic parseMessage(String message) {
  try {
    // Attempt to parse the message as JSON
    return json.decode(message);
  } catch (e) {
    // If parsing as JSON fails, return the original message
    return message;
  }
}

  void publishMessage(String topic, String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);

    print('Publishing message "$message" to topic $topic');
    client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }

  void _onSubscribed(String topic) {
    print('Subscription confirmed for topic $topic');
    subscriptionState = MqttSubscriptionState.SUBSCRIBED;
  }

void _onDisconnected() {
  print('OnDisconnected client callback - Client disconnection');
  connectionState = MqttCurrentConnectionState.DISCONNECTED;
  
  // Attempt reconnection
  _reconnect();
}

  void _onConnected() {
    connectionState = MqttCurrentConnectionState.CONNECTED;
    print('OnConnected client callback - Client connection was successful');
  }

void _reconnect() async {
  print('Attempting to reconnect...');
  connectionState = MqttCurrentConnectionState.CONNECTING;
  
  // Add a delay before attempting to reconnect to avoid flooding the server with connection requests
  await Future.delayed(Duration(seconds: 15));
  
  // Call _connectClient with your username and password
  await _connectClient('test-mobile-app', 'Test-mobile12');
  
  if (connectionState == MqttCurrentConnectionState.CONNECTED) {
    // If reconnection is successful, resubscribe to topics
    subscribedTopics.forEach(subscribeToTopic);
  } else {
    // If reconnection fails, schedule another attempt
    _reconnect();
  }
}

}
