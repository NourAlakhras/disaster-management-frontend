import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_3/models/user_credentials.dart';
import 'package:flutter_3/utils/constants.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

typedef MqttDataCallback = void Function(Map<String, dynamic> data);

class MQTTClientWrapper {
  MQTTClientWrapper._internal(); // private constructor

  static final MQTTClientWrapper _instance = MQTTClientWrapper._internal();

  factory MQTTClientWrapper() {
    return _instance;
  }
  late MqttServerClient client;
  MqttDataCallback onDataReceived = (data) {}; // Default no-op function
  Timer? _statusTimer;
  bool _showingDialog = false;

  Set<String> subscribedTopics = {};

void _startStatusTimer() {
    _statusTimer?.cancel();
    const timeoutDuration = Duration(seconds: 5); // Initial 5 seconds
    int elapsedTimeInSeconds = 0;
    // Print subscribed topics every 5 seconds
    if (elapsedTimeInSeconds % 5 == 0) {
      print('Subscribed Topics: $subscribedTopics');
    }

    _statusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedTimeInSeconds++;
      final status = client.connectionStatus;
      print(
          'MQTT Connection Status ${status?.state} , returnCode: ${status?.returnCode}');
      _connectionStatusController.add(status!.state);

      if (status.state != MqttConnectionState.connected &&
          elapsedTimeInSeconds >= 5) {
        _onDisconnected(); // Show dialog after 5 seconds if still connecting
      }

      if (status.state == MqttConnectionState.connected) {
        _statusTimer?.cancel(); // Cancel timer once connected
      }
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
      _listenToConnectionStatus();
      _listenToConnectivityChanges();
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
      client.keepAlivePeriod = 5;
      client.autoReconnect = true;
      client.onDisconnected = _onDisconnected;
      client.onConnected = _onConnected;
      client.onAutoReconnect = _onAutoReconnect;
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

        // Parse message to dynamic
        final dynamic data = parseMessage(message);

        // Check if data is a Map<String, dynamic>
        if (data is Map<String, dynamic>) {
          data['topic'] = c[0].topic;
          onDataReceived(data); // Safe to call as it's initialized
        } else if (data is List<dynamic>) {
          // Handle list of maps
          for (var item in data) {
            if (item is Map<String, dynamic>) {
              item['topic'] = c[0].topic;
              onDataReceived(item);
            } else {
              print(
                  'Received item in list is not a Map<String, dynamic>: $item');
            }
          }
        } else {
          print(
              'Received data is neither a Map<String, dynamic> nor a List: $data');
        }
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
      if (subscribedTopics.contains(topic)) {
        subscribedTopics.remove(topic);
        print('subscribedTopics after removal: $subscribedTopics');
        client.unsubscribe(topic);
        print('Unsubscribed from $topic');
      } else {
        print('Topic $topic was not in the subscribedTopics list');
      }
    } catch (e, stackTrace) {
      print('Error in unsubscribeFromTopic: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void unsubscribeFromMultipleTopics(List<String> topics) {
    try {
      topics.forEach((topic) {
        unsubscribeFromTopic(topic);
      });
    } catch (e, stackTrace) {
      print('Error in unsubscribeFromMultipleTopics: $e');
      print('Stack trace: $stackTrace');
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
      final parsed = json.decode(message);

      if (parsed is Map<String, dynamic> || parsed is List<dynamic>) {
        return parsed;
      } else {
        print('Parsed JSON is neither a Map nor a List: $parsed');
        return message; // or handle as needed
      }
    } catch (e, stackTrace) {
      print('Error in parseMessage: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
      return message; // Return the original message on error
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
      print(' hiiiiiiiiiiiiiii _subscribeToTopics _onConnected ');
      print('Connected to MQTT broker');
      print(' subscribedTopics  _onConnected  $subscribedTopics');
      // Dismiss reconnect dialogs if shown
      if (_showingDialog) {
        _showingDialog = false;
        Navigator.of(Constants.navigatorKey.currentState!.overlay!.context)
            .pop();
      }

      // Any other actions needed upon successful connection
    } catch (e, stackTrace) {
      print('Error in _onConnected: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
    }
  }

  StreamController<MqttConnectionState> _connectionStatusController =
      StreamController<MqttConnectionState>.broadcast();

  void _listenToConnectionStatus() {
    _connectionStatusController
        .close(); // Close previous controller if it exists
    _connectionStatusController =
        StreamController<MqttConnectionState>.broadcast();

    _connectionStatusController.stream.listen((MqttConnectionState state) {
      if (state == MqttConnectionState.connecting) {
        _onAutoReconnect();
      }
    });
  }

  Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  void _listenToConnectivityChanges() {
    _connectivitySubscription
        ?.cancel(); // Cancel previous subscription if exists
    _connectivitySubscription = _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> event) {
      // Note: 'event' is actually a single item list in this context
      ConnectivityResult result =
          event.isNotEmpty ? event[0] : ConnectivityResult.none;
      print('Connectivity changed to $result');
      if (result == ConnectivityResult.none) {
        _onDisconnected();
      }
    });
  }

Future<void> updateConnection() async {
    try {
      // Disconnect MQTT client
      client.disconnect(); // Disconnect current client

      // Stop auto reconnect and cancel any existing timers
      client.autoReconnect = false;
      _statusTimer?.cancel();

      // Clear subscribed topics
      if (subscribedTopics.isNotEmpty) {
        unsubscribeFromMultipleTopics(subscribedTopics.toList());
        subscribedTopics.clear();
      }

      // Close the old StreamController and initialize a new one
      _connectionStatusController.close();
      _connectionStatusController =
          StreamController<MqttConnectionState>.broadcast();

      // Cancel the existing connectivity subscription
      _connectivitySubscription?.cancel();

      // Re-initialize the MQTT client with new credentials
      await prepareMqttClient();
    } catch (e, stackTrace) {
      print('Error in updateConnection: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
    }
  }


  void logout() {
    try {
      // Disconnect MQTT client
      client.disconnect();

      // Stop auto reconnection
      client.autoReconnect = false;

      // Clear status timer
      _statusTimer?.cancel();

      // Clear subscribed topics
      if (MQTTClientWrapper().subscribedTopics.isNotEmpty) {
        MQTTClientWrapper().unsubscribeFromMultipleTopics(
            MQTTClientWrapper().subscribedTopics.toList());
        MQTTClientWrapper().subscribedTopics.clear();
      }
      _connectionStatusController.close();
      _connectivitySubscription?.cancel();


      _connectionStatusController =
          StreamController<MqttConnectionState>.broadcast();

    } catch (e, stackTrace) {
      print('Error in logout: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
    }
  }

  void _onAutoReconnect() {
    if (!_showingDialog) {
      _showingDialog = true;
      final BuildContext? context =
          Constants.navigatorKey.currentState?.overlay?.context;

      if (context == null) {
        print('Error: navigatorKey context is null');
        _showingDialog = false;
        return;
      }

      int elapsedTimeInSeconds = 0;
      Timer? reconnectTimer;

      // Show initial transparent dialog with progress indicator for the first 5 seconds
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            backgroundColor: Colors.transparent,
            content: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );

      // Start timer to switch to full dialog after 5 seconds
      reconnectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        elapsedTimeInSeconds++;
        final status = client.connectionStatus;

        if (status?.state != MqttConnectionState.connected &&
            elapsedTimeInSeconds >= 5) {
          // Cancel the initial transparent dialog
          Navigator.of(context).pop();

          // Show the full reconnect dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Connection Lost'),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Attempting to reconnect to MQTT...'),
                    SizedBox(height: 16),
                    CircularProgressIndicator(), // Add circular progress indicator
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Logout'),
                    onPressed: () {
                      logout();
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/', (route) => false);
                    },
                  ),
                ],
              );
            },
          ).then((value) => _showingDialog = false);

          reconnectTimer?.cancel();
        }
      });
    }
  }
}
