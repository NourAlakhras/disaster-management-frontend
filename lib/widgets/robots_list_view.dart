import 'package:flutter/material.dart';
import 'package:flutter_3/models/robot.dart';
import 'package:flutter_3/screens/robot_detailed_screen.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';

class RobotsListView extends StatefulWidget {
  final MQTTClientWrapper mqttClient;
  final List<Robot> robots;



  RobotsListView({required this.mqttClient, required this.robots,});

  @override
  State<RobotsListView> createState() => _RobotsListViewState();
}

class _RobotsListViewState extends State<RobotsListView> {
  Map<String, int> batteryLevels = {}; // Store battery levels for each robot
  Map<String, int> wifiLevels = {}; // Store Wi-Fi levels for each robot

  @override
  void initState() {
    super.initState();
    _subscribeToTopics();
  }

  void _subscribeToTopics() {
    widget.robots.forEach((robot) {
      List<String> mqttTopics = [
        '${robot.id}/battery',
        '${robot.id}/connectivity',
      ];
      widget.mqttClient.subscribeToMultipleTopics(mqttTopics);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff121417),
      child: ListView.builder(
        itemCount: widget.robots.length,
        itemBuilder: (context, index) {
          Robot robot = widget.robots[index];
          List<String> mqttTopics = [
                    '${robot.id}/battery',
                    '${robot.id}/connectivity',
                  ];
          widget.mqttClient.subscribeToMultipleTopics(mqttTopics);
          return GestureDetector(
            onTap: () {
              
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RobotDetailedScreen(
                    mqttClient: widget.mqttClient,
                    robotId: robot.id,                 
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
                              robot.name,
                              style: const TextStyle(
                                color: Colors.white, 
                                fontSize: 18, 
                                fontWeight: FontWeight.bold, 
                              ),
                            ),
                            const SizedBox(height: 8),

                            Text(
                              'Battery: ${batteryLevels[robot.id] ?? 'Unknown'}%',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'WI-FI: ${wifiLevels[robot.id] ?? 'Unknown'}%',
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
}