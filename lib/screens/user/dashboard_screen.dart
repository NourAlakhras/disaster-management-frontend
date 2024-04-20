import 'package:flutter/material.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';

class DashboardScreen extends StatelessWidget {
  final MQTTClientWrapper mqttClient; // Declare mqttClient as a member variable

  const DashboardScreen({Key? key, required this.mqttClient}) : super(key: key); // Update constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121417),
      appBar: CustomUpperBar(
        title: 'Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: const Color.fromARGB(255, 255, 255, 255),
            onPressed: () {},
          )
        ],
      ),
      body: const Center(
        child: Text('Dashboard Content'),
      ),
    );
  }
}
