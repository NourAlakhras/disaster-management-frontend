import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:flutter_3/utils/app_colors.dart';
import 'package:flutter_3/services/device_api_service.dart'; // Import your device API service

class ControllingView extends StatefulWidget {
  final Device device;
  final MQTTClientWrapper mqttClient;
  final Device? broker;

  const ControllingView({
    Key? key,
    required this.device,
    required this.mqttClient,
    required this.broker,
  }) : super(key: key);

  @override
  _ControllingViewState createState() => _ControllingViewState();
}

class _ControllingViewState extends State<ControllingView> {
  double _x1 = 0;
  double _y1 = 0;
  double _x2 = 0;
  double _y2 = 0;

  @override
  void initState() {
    super.initState();
    // Set device state to 'control' when entering the tab
    updateDeviceState('control');
  }

  @override
  void dispose() {
    // Set device state to 'auto' when leaving the tab
    updateDeviceState('auto');
    super.dispose();
  }

  void updateDeviceState(String state) {
    try {
      DeviceApiService.updateDeviceState(
        deviceId: widget.device.device_id,
        newState: state,
      );
      print('device state updated ');
    } catch (e) {
      print('Failed to update device state: $e');
      // Handle error if needed
    }
  }

  void _publishMessage({
    required String device,
    required String command,
    List<double>? value,
  }) {
    Map<String, dynamic> message = {
      'device': device,
      'command': command,
    };

    if (value != null) {
      message['value'] = value;
    }

    final topic =
        'cloud/reg/${widget.broker?.name}/${widget.device.name}/control';

    final messageJson = jsonEncode(message);

    print('Publishing to topic: $topic');
    print('Message: $messageJson');

    widget.mqttClient.publishMessage(topic, messageJson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Camera: ',
                          style:
                              TextStyle(color: primaryTextColor, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '(${_x1.toStringAsFixed(2)}, ${_y1.toStringAsFixed(2)})',
                          style: const TextStyle(
                              color: secondaryTextColor, fontSize: 14),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Joystick(
                              mode: JoystickMode.all,
                              listener: (details) {
                                setState(() {
                                  _x1 = details.x;
                                  _y1 = details.y;
                                  print(
                                      'Joystick 1 coordinates: (${_x1.toStringAsFixed(2)}, ${_y1.toStringAsFixed(2)})');
                                  _publishMessage(
                                      device: 'camera',
                                      command: 'move',
                                      value: [_x1, _y1]);
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Robot: ',
                          style:
                              TextStyle(color: primaryTextColor, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '(${_x2.toStringAsFixed(2)}, ${_y2.toStringAsFixed(2)})',
                          style: const TextStyle(
                              color: secondaryTextColor, fontSize: 14),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Joystick(
                              mode: JoystickMode.all,
                              listener: (details) {
                                setState(() {
                                  _x2 = details.x;
                                  _y2 = details.y;
                                  print(
                                      'Joystick 2 coordinates: (${_x2.toStringAsFixed(2)}, ${_y2.toStringAsFixed(2)})');
                                  _publishMessage(
                                      device: 'motor',
                                      command: 'move',
                                      value: [_x2, _y2]);
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text(
                    'Arm: ',
                    style: TextStyle(color: primaryTextColor, fontSize: 18),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      print('Grab button pressed');
                      _publishMessage(device: 'arm', command: 'grab');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 8),
                    ),
                    child: const Text('Grab'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      print('Release button pressed');
                      _publishMessage(device: 'arm', command: 'release');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 8),
                    ),
                    child: const Text('Release'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
