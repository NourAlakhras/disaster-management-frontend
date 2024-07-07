import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/screens/user/device_detailed_screen.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/services/rtmp_client_service.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:flutter_3/utils/app_colors.dart';

class MissionDevicesThumbnailsTab extends StatefulWidget {
  final MQTTClientWrapper mqttClient;
  final List<Device> devices;
    final Device? broker;

  const MissionDevicesThumbnailsTab({
    super.key,
    required this.mqttClient,
    required this.devices, required this.broker,
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
  final RTMPClientService _rtmpClientService = RTMPClientService();
  late Timer _reconnectTimer;
  late Map<String, bool> _isPlayerInitializedMap =
      {}; // Map to track player initialization state for each device

  @override
  void initState() {
    super.initState();
    _subscribeToTopics();
    _startReconnectTimer();
  }

  void _initializePlayer() async {
    for (var device in widget.devices) {
      await _rtmpClientService.initializePlayer(
        deviceId: device.device_id,
        deviceName: device.name,
      );
      _isPlayerInitializedMap[device.device_id] =
          true; // Mark the player as initialized for the current device
    }
    setState(() {});
  }

  void _startReconnectTimer() {
    for (var device in widget.devices) {
      _reconnectTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (!_rtmpClientService
            .getController(device.device_id)
            .value
            .isInitialized) {
          _initializePlayer();
        }
      });
    }
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
    return Column(
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
                    style: TextStyle(color: primaryTextColor),
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
                                                broker: widget.broker,

                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: barColor,
                        ),
                      ),
                    ),
                    child: Container(
                      color: Colors.transparent,
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
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
                                      color: primaryTextColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Type: ${device.type.toString().split('.').last.toLowerCase()}',
                                    style: const TextStyle(
                                      color: secondaryTextColor,
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
                                            color: secondaryTextColor,
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
                                            color: secondaryTextColor,
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
                                    color: secondaryTextColor,
                                    child: Center(
                                      child: _isPlayerInitializedMap[
                                                  device.device_id] ??
                                              false
                                          ? VlcPlayer(
                                              controller: _rtmpClientService
                                                  .getController(
                                                      device.device_id),
                                              aspectRatio: aspectRatio,
                                              placeholder: const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            )
                                          : const Center(
                                              child:
                                                  CircularProgressIndicator(),
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
                        foregroundColor: accentColor,
                        backgroundColor: secondaryTextColor,
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
                        foregroundColor: accentColor,
                        backgroundColor: secondaryTextColor,
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
      _rtmpClientService.disposeController(device.device_id);
    }
    _rtmpClientService.disposeAll();
    super.dispose();
  }
}
