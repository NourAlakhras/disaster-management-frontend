import 'package:flutter/material.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/custom_search_bar.dart';
import 'package:flutter_3/widgets/robots_list_view.dart';
import 'package:flutter_3/widgets/robots_map_view.dart';
import 'package:flutter_3/widgets/tabbed_view.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart'; // Import the MQTTClientWrapper

class RobotsListScreen extends StatelessWidget {
  final MQTTClientWrapper mqttClient; // Declare mqttClient as a member variable

  const RobotsListScreen({Key? key, required this.mqttClient}) : super(key: key); 
 // Update constructor
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121417),
      appBar: CustomUpperBar(
        title: 'Robots',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: const Color.fromARGB(255, 255, 255, 255),
            onPressed: () {},
          )
        ],
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child:  Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: CustomSearchBar(),
                    ),
                  ),
                  Icon(Icons.filter_alt, color: Colors.white),
                ],
              ),
            ),
            Expanded(
              child: TabbedView(
                length: 2,
                tabs: const <Widget>[
                  Tab(
                    child: Icon(Icons.list),
                  ),
                  Tab(
                    icon: Icon(Icons.map_outlined),
                    // text: 'Map',
                  ),
                ],
                tabContents: <Widget>[
                  // Content for Tab 1
                  RobotsListView(mqttClient: mqttClient),
                  // Content for Tab 2 (replace with your map view widget)
                  RobotsMapView(mqttClient: mqttClient),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
