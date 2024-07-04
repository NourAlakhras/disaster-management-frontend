import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:flutter_3/utils/app_colors.dart';

class ControllingView extends StatefulWidget {
  final Device device;
  final MQTTClientWrapper mqttClient;

  const ControllingView({
    super.key,
    required this.device,
    required this.mqttClient,
  });

  @override
  _ControllingViewState createState() => _ControllingViewState();
}

class _ControllingViewState extends State<ControllingView> {
  double _x1 = 0;
  double _y1 = 0;
  double _x2 = 0;
  double _y2 = 0;

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
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 8), // Button padding
                    ),
                    child: const Text('Grab'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      print('Release button pressed');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 8), // Button padding
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
