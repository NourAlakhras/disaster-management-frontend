import 'package:flutter/material.dart';
import 'package:flutter_3/models/robot.dart';
import 'package:flutter_3/screens/robot_detailed_screen.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart'; // Import the RobotDetailedScreen

class RobotsListView extends StatelessWidget {
  final MQTTClientWrapper mqttClient; // Declare mqttClient as a member variable

  final List<Robot> robots = [
    Robot(id: "1", name: 'Robot 1', batteryStatus: 80),
    Robot(id: "2", name: 'Robot 2', batteryStatus: 60),
    Robot(id: "3", name: 'Robot 3', batteryStatus: 90),
    //more robots as needed
  ];

  RobotsListView({required this.mqttClient}); // Update constructor


  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff121417),
      child: ListView.builder(
        itemCount: robots.length,
        itemBuilder: (context, index) {
          Robot robot = robots[index];
          return GestureDetector(
            onTap: () {
              // Construct the MQTT topic based on the robot ID
              // String mqttTopic = '${robot.id}/sensor_data';
              String mqttTopic = 'test-ugv/sensor_data';
              // Navigate to RobotDetailedScreen when card is tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RobotDetailedScreen(
                    mqttClient: mqttClient,
                    robotId: robot.id,
                    mqttTopic: mqttTopic, // Pass the MQTT topic to the detailed screen
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
                                color: Colors.white, // Custom color for the title text
                                fontSize: 18, // Custom font size for the title text
                                fontWeight: FontWeight.bold, // Make the title bold
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Battery: ${robot.batteryStatus}%',
                              style: const TextStyle(
                                color: Colors.white60, // Custom color for the subtitle text
                                fontSize: 16, // Custom font size for the subtitle text
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16), // Add spacing between card content and video placeholder
                      Container(
                        width: 175,
                        height: 175, // Adjust size of the video placeholder
                        color: Colors.grey[300], // Placeholder color
                        child: Center(
                          child: Icon(
                            Icons.video_library,
                            size: 100,
                            color: Colors.grey[600], // Icon color
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