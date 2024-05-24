import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/screens/user/device_detailed_screen.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/enums.dart';

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
  int _pageNumber = 1;
  final int _pageSize = 3;
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
    int startIndex = (_pageNumber - 1) * _pageSize;
    int endIndex = startIndex + _pageSize;
    List<Device> currentDevices = widget.devices.sublist(startIndex,
        endIndex > widget.devices.length ? widget.devices.length : endIndex);

    // Get half of the screen width
    double screenWidth = (MediaQuery.of(context).size.width) / 2;
    print('screenWidth $screenWidth');

    double aspectRatio = 16 / 9;

    // Calculate the height based on the aspect ratio
    double videoHeight = screenWidth / aspectRatio;
    return Container(
      color: const Color(0xff121417),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: currentDevices.length,
              itemBuilder: (context, index) {
                Device device = currentDevices[index];
                if (currentDevices.isEmpty) {
                  return const Center(
                    child: Text(
                      'No devices available',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                } else {
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
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                          color: Color(0xff293038),
                        )),
                      ),
                      child: Container(
                        color: Colors.transparent,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
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
                                    const SizedBox(height: 3),
                                    Text(
                                      'Type: ${device.type.toString().split('.').last.toLowerCase()}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    device.type !=
                                                DeviceType.CHARGING_STATION &&
                                            device.type != DeviceType.BROKER
                                        ? Text(
                                            'Battery: ${batteryLevels[device.device_id] ?? 'Unknown'}%',
                                            style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 14,
                                            ),
                                          )
                                        : SizedBox(),
                                    device.type !=
                                                DeviceType.CHARGING_STATION &&
                                            device.type != DeviceType.BROKER
                                        ? Text(
                                            'WI-FI: ${wifiLevels[device.device_id] ?? 'Unknown'}%',
                                            style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 14,
                                            ),
                                          )
                                        : SizedBox(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 2),
                              device.type != DeviceType.CHARGING_STATION &&
                                      device.type != DeviceType.BROKER
                                  ? Container(
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
                                    )
                                  : const SizedBox(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10.0, 20, 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _pageNumber > 1
                    ? ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (_pageNumber > 1) _pageNumber--;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white70,
                          elevation: 0, // No shadow
                          shape: const CircleBorder(), // Circular button shape
                        ),
                        child: const Icon(Icons.arrow_back),
                      )
                    : const SizedBox(width: 48, height: 48),
                _pageNumber < (widget.devices.length / _pageSize).ceil()
                    ? ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (_pageNumber <
                                (widget.devices.length / _pageSize).ceil()) {
                              _pageNumber++;
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white70,
                          elevation: 0, // No shadow
                          shape: const CircleBorder(), // Circular button shape
                        ),
                        child: const Icon(Icons.arrow_forward),
                      )
                    : const SizedBox(width: 48, height: 48),
              ],
            ),
          ),
        ],
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
