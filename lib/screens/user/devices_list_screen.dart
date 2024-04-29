import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/custom_search_bar.dart';
import 'package:flutter_3/widgets/robots_list_view.dart';
import 'package:flutter_3/widgets/robots_map_view.dart';
import 'package:flutter_3/widgets/tabbed_view.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/models/robot.dart';

class DevicesListScreen extends StatefulWidget {
  final MQTTClientWrapper mqttClient;

  const DevicesListScreen({super.key, required this.mqttClient});

  @override
  State<DevicesListScreen> createState() => _DevicesListScreenState();
}


class _DevicesListScreenState extends State<DevicesListScreen> {
  List<Device> _devices = []; // List to store the fetched devices

  @override
  void initState() {
    super.initState();
    _fetchDevices(); // Call the method to fetch devices when the widget initializes
  }

  Future<void> _fetchDevices() async {
    try {
      // Call the getAllDevices method from the DeviceApiService
      List<Device> devices = await DeviceApiService.getAllDevices(pageNumber: 1, pageSize: 7);
      setState(() {
        _devices = devices; // Update the state with the fetched devices
      });
    } catch (error) {
      // Handle error if fetching devices fails
      print('Failed to fetch devices: $error');
    }
  }
  final TextEditingController _searchController = TextEditingController();
  List<Device> _filteredRobots = [];
  final List<Device> _allRobots = [];

  final List<Robot> robots = [
    Robot(id: "1", name: 'Robot 1'),
    Robot(id: "2", name: 'Robot 2'),
    Robot(id: "3", name: 'Robot 3'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121417),
      appBar: CustomUpperBar(
        title: 'Robots',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 8, 15.0, 00),
              child: CustomSearchBar(
                controller: _searchController,
                onChanged: _filterRobots,
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
                  ),
                ],
                tabContents: <Widget>[
                  // Content for Tab 1
                  RobotsListView(mqttClient: widget.mqttClient, robots: robots),
                  // Content for Tab 2
                  RobotsMapView(mqttClient: widget.mqttClient, robots: robots),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _filterRobots(String query) {
    setState(() {
      if (query.isNotEmpty) {
        _filteredRobots = _allRobots
            .where(
                (user) => user.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else {
        _filteredRobots = _allRobots;
      }
    });
  }

  _showStatusFilterDialog() {}

  _showTypeFilterDialog() {}
}
