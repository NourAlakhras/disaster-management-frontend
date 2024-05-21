import 'package:flutter/material.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/custom_search_bar.dart';
import 'package:flutter_3/widgets/devices_list_view.dart';
import 'package:flutter_3/widgets/devices_map_view.dart';
import 'package:flutter_3/widgets/tabbed_view.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
class MissionDevicesListScreen extends StatefulWidget {
  final MQTTClientWrapper mqttClient;
  final Mission mission;

  const MissionDevicesListScreen(
      {required this.mqttClient, super.key, required this.mission});

  @override
  State<MissionDevicesListScreen> createState() =>
      _MissionDevicesListScreenState();
}

class _MissionDevicesListScreenState extends State<MissionDevicesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121417),
      appBar: CustomUpperBar(
        title: 'Mission: ${widget.mission.name}',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color.fromARGB(255, 255, 255, 255),
          onPressed: () {
            Navigator.pop(context);
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
                onChanged: _filterDevices,
                onClear: _clearSearch,
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
                  if (widget.mission.devices != null &&
                      widget.mission.devices!.isNotEmpty)
                    DevicesListView(
                      mqttClient: widget.mqttClient,
                      devices:
                          widget.mission.devices!, // Use devices from mission
                    )
                    else
                    const Center(
                      child: Text('No devices available',
                          style: TextStyle(color: Colors.white)),
                    ),
                  // Content for Tab 2
                  if (widget.mission.devices != null &&
                      widget.mission.devices!.isNotEmpty)
                    DevicesMapView(
                      mqttClient: widget.mqttClient,
                      devices:
                          widget.mission.devices!, // Use devices from mission
                    )
                  else
                    const Center(
                      child: Text('No devices available',
                          style: TextStyle(color: Colors.white)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _filterDevices(String query) {
    // Implement device filtering logic here
  }


void _clearSearch() {
    // Clear the search query
    _searchController.clear();
    // Call filterMissions with an empty string to reset the filtered list
    _filterDevices('');
  }
}
