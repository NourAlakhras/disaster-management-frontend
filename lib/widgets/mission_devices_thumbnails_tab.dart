import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/screens/user/device_detailed_screen.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';

class MissionDevicesThumbnailsTab extends StatefulWidget {
  final MQTTClientWrapper mqttClient;
  final List<Device> devices;

  const MissionDevicesThumbnailsTab({
    super.key,
    required this.mqttClient,
    required this.devices,
  });
  @override
  State<MissionDevicesThumbnailsTab> createState() =>
      _MissionDevicesThumbnailsTabState();
}

class _MissionDevicesThumbnailsTabState
    extends State<MissionDevicesThumbnailsTab> {
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
        '${device.device_id}/battery',
        '${device.device_id}/connectivity',
      ];

      widget.mqttClient.subscribeToMultipleTopics(mqttTopics);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get half of the screen width
    double screenWidth = (MediaQuery.of(context).size.width) / 2;
    print('screenWidth $screenWidth');

    double aspectRatio = 16 / 9;

    // Calculate the height based on the aspect ratio
    double videoHeight = screenWidth / aspectRatio;
    return Container(
      color: const Color(0xff121417),
      child: ListView.builder(
        itemCount: widget.devices.length,
        itemBuilder: (context, index) {
          Device device = widget.devices[index];
          List<String> mqttTopics = [
            '${device.device_id}/battery',
            '${device.device_id}/connectivity',
          ];
          widget.mqttClient.subscribeToMultipleTopics(mqttTopics);
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeviceDetailedScreen(
                    mqttClient: widget.mqttClient,
                    device: device,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                  color: Color(0xff293038),
                )),
              ),
              child: Container(
                color: Colors.transparent,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
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
                              'Type: ${device.type.toString().split('.').last.toLowerCase()}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Battery: ${batteryLevels[device.device_id] ?? 'Unknown'}%',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'WI-FI: ${wifiLevels[device.device_id] ?? 'Unknown'}%',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: screenWidth,
                        height: videoHeight,
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
        '${device.device_id}/battery',
        '${device.device_id}/connectivity',
      ];
      widget.mqttClient.unsubscribeFromMultipleTopics(mqttTopics);
    }
    super.dispose();
  }
}
