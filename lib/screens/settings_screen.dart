import 'package:flutter/material.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

   @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: const Color(0xff121417),
      appBar: CustomUpperBar(
        title: 'Settings',actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: const Color.fromARGB(255, 255, 255, 255),
            onPressed: () {},
          )
        ],
      ),
      body: const Center(
        child: Text('Settings Content'),
      ),
    );
  }
}

