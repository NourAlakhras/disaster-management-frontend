import 'dart:async';
import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/sensor_data.dart';
import 'package:flutter_3/screens/device_detailed_screen.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/services/rtmp_client_service.dart';
import 'package:flutter_3/providers/sensor_data_provider.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:flutter_3/utils/app_colors.dart';
import 'package:provider/provider.dart' as prov;

class MissionDevicesThumbnailsTab extends StatefulWidget {
  final MQTTClientWrapper mqttClient;
  final List<Device> devices;
  final Device? broker;

  const MissionDevicesThumbnailsTab({
    super.key,
    required this.mqttClient,
    required this.devices,
    required this.broker,
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
  final int _pageSize = 4;
  final RTMPClientService _rtmpClientService = RTMPClientService();
  late Timer _reconnectTimer;
  late Map<String, bool> _isPlayerInitializedMap =
      {}; // Map to track player initialization state for each device

  @override
  void initState() {
    super.initState();
    _initializePlayers(); // Initialize players once
    _startReconnectTimer();
  }

  Future<void> _initializePlayers() async {
      if (!mounted) return; // Check if the widget is still in the widget tree

    final futures = widget.devices.map((device) {
      return _rtmpClientService
          .initializePlayer(
        deviceId: device.device_id,
        deviceName: device.name,
      )
          .then((_) {
        setState(() {
          _isPlayerInitializedMap[device.device_id] = true;
        });
      }).catchError((error) {
        print(
            'Error initializing player for device ${device.device_id}: $error');
        setState(() {
          _isPlayerInitializedMap[device.device_id] = false;
        });
      });
    }).toList();
    await Future.wait(futures); // Wait for all players to be initialized
  }

  void _checkPlayerState(String deviceId) {
    final controller = _rtmpClientService.getController(deviceId);
    if (controller != null) {
      final value = controller.value;
      print('Controller state for device $deviceId: $value');

      if (!value.isInitialized) {
        print('Player for device $deviceId is not initialized.');
        // Handle reinitialization if needed
      } else if (value.isBuffering) {
        print('Player for device $deviceId is buffering.');
        // Handle buffering state
      }
    } else {
      print('No controller found for device $deviceId.');
    }
  }

  void _startReconnectTimer() {
    _reconnectTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      for (var device in widget.devices) {
        final controller = _rtmpClientService.getController(device.device_id);
        if (controller == null || !controller.value.isInitialized) {
          print('Reinitializing player for device: ${device.device_id}');
          _rtmpClientService
              .initializePlayer(
            deviceId: device.device_id,
            deviceName: device.name,
          )
              .then((_) {
            setState(() {
              _isPlayerInitializedMap[device.device_id] = true;
            });
          }).catchError((error) {
            print(
                'Error reinitializing player for device ${device.device_id}: $error');
            setState(() {
              _isPlayerInitializedMap[device.device_id] = false;
            });
          });
        }

        // Check player state
        _checkPlayerState(device.device_id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int startIndex = (_pageNumber - 1) * _pageSize;
    int endIndex = startIndex + _pageSize;
    List<Device> currentDevices = widget.devices.sublist(startIndex,
        endIndex > widget.devices.length ? widget.devices.length : endIndex);

    double screenWidth = (MediaQuery.of(context).size.width) / 2;
    double aspectRatio = 16 / 9;
    double videoHeight = screenWidth / aspectRatio;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: currentDevices.length,
            itemBuilder: (context, index) {
              Device device = currentDevices[index];
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
                                device.type != DeviceType.CHARGING_STATION &&
                                        device.type != DeviceType.BROKER
                                    ? prov.Consumer<SensorDataProvider>(
                                        builder:
                                            (context, sensorDataProvider, _) {
                                          final batteryKey =
                                              '${device.name}/battery';
                                          SensorData? batteryData =
                                              sensorDataProvider
                                                  .sensorData[batteryKey];
                                          return Text(
                                            'Battery: ${batteryData != null ? batteryData.value.toStringAsFixed(2) : 'Unknown ${batteryData?.unit.toString()}'}',
                                            style: const TextStyle(
                                              color: secondaryTextColor,
                                              fontSize: 14,
                                            ),
                                          );
                                        },
                                      )
                                    : const SizedBox(),
                                device.type != DeviceType.CHARGING_STATION &&
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
                                                        device.device_id) ??
                                                VlcPlayerController.network(''),
                                            aspectRatio: aspectRatio,
                                            placeholder: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          )
                                        : const Center(
                                            child: CircularProgressIndicator(),
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
    _reconnectTimer.cancel();
    for (var device in widget.devices) {
      _rtmpClientService.disposeController(device.device_id);
    }
    _rtmpClientService.disposeAll();
    super.dispose();
  }
}
