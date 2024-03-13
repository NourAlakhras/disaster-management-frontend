import 'package:flutter/material.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';


class RobotsMapView extends StatefulWidget {
  final MQTTClientWrapper mqttClient; // Declare mqttClient as a member variable

  const RobotsMapView({required this.mqttClient}); // Update constructor

  @override
  State<RobotsMapView> createState() => _RobotsMapViewState();
}

class _RobotsMapViewState extends State<RobotsMapView> {
  
  @override
  Widget build(BuildContext context) {
    
    return  
      Expanded(child: Container(color: const Color(0xff121417),
                    child: const Center(
                      child: Icon(
                        Icons.map_outlined,
                        size: 200,
                        color: Colors.white, // Icon color
                      ),
                    ),
      ));
  }
}
