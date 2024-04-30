import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/screens/user/device_detailed_screen.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';

class DevicesListView extends StatefulWidget {
  final MQTTClientWrapper mqttClient;
  final List<Device> devices;



  const DevicesListView({super.key, required this.mqttClient, required this.devices,});

  @override
  State<DevicesListView> createState() => _DevicesListViewState();
}

class _DevicesListViewState extends State<DevicesListView> {
  Map<String, int> batteryLevels = {}; // Store battery levels for each device
  Map<String, int> wifiLevels = {}; // Store Wi-Fi levels for each device

  @override
  void initState() {
    super.initState();
    _subscribeToTopics();
  }

  void _subscribeToTopics() {
    for (var device in widget.devices) {
      List<String> mqttTopics = [
        '${device.id}/battery',
        '${device.id}/connectivity',
      ];

          widget.mqttClient.subscribeToMultipleTopics(mqttTopics);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff121417),
      child: ListView.builder(
        itemCount: widget.devices.length,
        itemBuilder: (context, index) {
          Device device = widget.devices[index];
          List<String> mqttTopics = [
                    '${device.id}/battery',
                    '${device.id}/connectivity',
                  ];
          widget.mqttClient.subscribeToMultipleTopics(mqttTopics);
          return GestureDetector(
            onTap: () {
              
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeviceDetailedScreen(
                    mqttClient: widget.mqttClient,
                    deviceId: device.id,                 
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Card(
                color: const Color(0xff121417),
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name,
                              style: const TextStyle(
                                color: Colors.white, 
                                fontSize: 18, 
                                fontWeight: FontWeight.bold, 
                              ),
                            ),
                            const SizedBox(height: 8),

                            Text(
                              'Battery: ${batteryLevels[device.id] ?? 'Unknown'}%',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'WI-FI: ${wifiLevels[device.id] ?? 'Unknown'}%',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16), 
                      Container(
                        width: 175,
                        height: 175, 
                        color: Colors.grey[300], 
                        child: Center(
                          child: Icon(
                            Icons.video_library,
                            size: 100,
                            color: Colors.grey[600], 
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
    @override
  void dispose() {
        for (var device in widget.devices) {
      List<String> mqttTopics = [
        '${device.id}/battery',
        '${device.id}/connectivity',
      ];
      widget.mqttClient.unsubscribeFromMultipleTopics(mqttTopics);
        }   
super.dispose();
  }
}