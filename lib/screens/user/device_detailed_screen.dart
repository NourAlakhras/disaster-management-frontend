import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/widgets/monitoring_view.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/tabbed_view.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

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
  late VlcPlayerController _videoPlayerController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VlcPlayerController.network(
      'rtmp://192.168.68.126/live/test',
      autoPlay: true,
      
      onRendererHandler: (eventType, id, event) {
        switch (eventType) {
          case VlcRendererEventType.attached:
            print('Renderer attached: $event');
            break;
          case VlcRendererEventType.detached:
            print('Renderer detached: $event');
            break;
          case VlcRendererEventType.unknown:
            print('Unknown renderer event: $event');
            break;
        }
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    // Get the screen width
    double aspectRatio = 16 / 10; // Adjust as needed
    double screenWidth = MediaQuery.of(context).size.width;
    double videoHeight = screenWidth / aspectRatio;

    // Calculate the height based on the aspect ratio

    return Scaffold(
      backgroundColor: const Color(0xff121417),
      appBar: CustomUpperBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color.fromARGB(255, 255, 255, 255),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: 'Device: ${widget.device.name}',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: const Color.fromARGB(255, 255, 255, 255),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          VlcPlayer(
            controller: _videoPlayerController,
            aspectRatio: aspectRatio,
            placeholder: const Center(child: CircularProgressIndicator()),
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
                    deviceId: widget.device.device_id,
                    mqttClient: widget.mqttClient,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  child: const Text('Controlling'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
