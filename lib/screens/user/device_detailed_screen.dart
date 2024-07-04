import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/services/rtmp_client_service.dart';
import 'package:flutter_3/widgets/controlling_view.dart';
import 'package:flutter_3/widgets/monitoring_view.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/tabbed_view.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'dart:async';
import 'package:flutter_3/utils/app_colors.dart';

class DeviceDetailedScreen extends StatefulWidget {
  final Device device;
  final MQTTClientWrapper mqttClient;

  const DeviceDetailedScreen({
    super.key,
    required this.device,
    required this.mqttClient,
  });

  @override
  State<DeviceDetailedScreen> createState() => _DeviceDetailedScreenState();
}

class _DeviceDetailedScreenState extends State<DeviceDetailedScreen> {
  final RTMPClientService _rtmpClientService = RTMPClientService();
  late Timer _reconnectTimer;
  bool _isPlayerInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _startReconnectTimer();
  }

  Future<void> _initializePlayer() async {
    await _rtmpClientService.initializePlayer(
      deviceId: widget.device.device_id,
      deviceName: widget.device.name,
    );
    setState(() {
      _isPlayerInitialized = true;
    });
  }

  void _startReconnectTimer() {
    _reconnectTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_rtmpClientService
          .getController(widget.device.device_id)
          .value
          .isInitialized) {
        _initializePlayer();
      }
    });
  }

  @override
  void dispose() {
    _rtmpClientService.disposeController(widget.device.device_id);
    _reconnectTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width
    double aspectRatio = 16 / 10; // Adjust as needed
    double screenWidth = MediaQuery.of(context).size.width;
    double videoHeight = screenWidth / aspectRatio;

    // Calculate the height based on the aspect ratio

    return Scaffold(
      appBar: CustomUpperBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: primaryTextColor,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: 'Device: ${widget.device.name}',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: primaryTextColor,
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            width: screenWidth,
            height: videoHeight,
            color: secondaryTextColor,
            child: Center(
              child: _isPlayerInitialized
                  ? VlcPlayer(
                      controller: _rtmpClientService
                          .getController(widget.device.device_id),
                      aspectRatio: aspectRatio,
                      placeholder: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            ),
          ),
          Expanded(
            child: TabbedView(
              length: 2,
              tabs: const <Widget>[
                Tab(
                  text: 'Monitoring',
                ),
                Tab(
                  text: 'Controlling',
                ),
              ],
              tabContents: [
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  child: MonitoringView(
                    device: widget.device,
                    mqttClient: widget.mqttClient,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  child: ControllingView(
                    device: widget.device,
                    mqttClient: widget.mqttClient,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
