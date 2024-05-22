import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/custom_search_bar.dart';
import 'package:flutter_3/widgets/devices_list_view.dart';
import 'package:flutter_3/widgets/devices_map_view.dart';
import 'package:flutter_3/widgets/devices_thumbnails_view.dart';
import 'package:flutter_3/widgets/tabbed_view.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';

class DevicesBaseScreen extends StatefulWidget {
  final MQTTClientWrapper mqttClient;

  const DevicesBaseScreen({required this.mqttClient, super.key});

  @override
  State<DevicesBaseScreen> createState() => _DevicesBaseScreenState();
}

class _DevicesBaseScreenState extends State<DevicesBaseScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121417),
      appBar: CustomUpperBar(
        title: 'Devices',
        leading: IconButton(
          icon: const Icon(Icons.settings),
          color: Colors.white,
          onPressed: () {
            // Handle settings icon tap
          },
        ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: TabbedView(
                length: 3,
                tabs: const <Widget>[
                  Tab(
                    child: Icon(Icons.list),
                  ),
                  Tab(
                    child: Icon(Icons.grid_view_rounded),
                  ),
                  Tab(
                    icon: Icon(Icons.map_outlined),
                  ),
                ],
                tabContents: <Widget>[
                  // Content for Tab 1

                    DevicesListView(
                      mqttClient: widget.mqttClient,
                    ),
            
                  // Content for Tab 2
                 
                    DevicesThumbnailsView(
                      mqttClient: widget.mqttClient,
                    ),
                  // Content for Tab 3


                    DevicesMapView(
                      mqttClient: widget.mqttClient,
                    )
                
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
