import 'package:flutter/material.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/services/api_service.dart'; // Import the ApiService to call the logout method

class SettingsScreen extends StatelessWidget {
  final MQTTClientWrapper mqttClient;

  const SettingsScreen({Key? key, required this.mqttClient}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    try {
      // Disconnect from MQTT

      await mqttClient.logout(); // Use existing mqttClient instance
      // Call the logout method
      await ApiService.logout();

      // Navigate back to the login screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/', // Replace '/' with the route name of your login screen
        (route) => false,
      );
    } catch (e) {
      // Handle logout failure
      print('Failed to logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121417),
      appBar: CustomUpperBar(
        title: 'Settings',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: const Color.fromARGB(255, 255, 255, 255),
            onPressed: () {
              // Handle notifications action
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout), // Add logout button icon
            color: const Color.fromARGB(255, 255, 255, 255),
            onPressed: () => _logout(context), // Call _logout method
          ),
        ],
      ),
      body: const Center(
        child: Text('Settings Content'),
      ),
    );
  }
}
