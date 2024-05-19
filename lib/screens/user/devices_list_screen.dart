import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/custom_search_bar.dart';
import 'package:flutter_3/widgets/devices_list_view.dart';
import 'package:flutter_3/widgets/devices_map_view.dart';
import 'package:flutter_3/widgets/tabbed_view.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
class DevicesListScreen extends StatefulWidget {
  final MQTTClientWrapper mqttClient;

  const DevicesListScreen({required this.mqttClient, super.key});

  @override
  State<DevicesListScreen> createState() => _DevicesListScreenState();
}

class _DevicesListScreenState extends State<DevicesListScreen> {
  List<Device> _devices = [];
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _fetchDevices(); // Call the method to fetch devices when the widget initializes
  }

  Future<void> _fetchDevices() async {
    try {
      // Call the getAllDevices method from the DeviceApiService
      List<Device> devices =
          await DeviceApiService.getAllDevices(pageNumber: 1, pageSize: 7);
      setState(() {
        _devices = devices; // Update the state with the fetched devices
        print('devices $devices');
      });
    } catch (error) {
      // Handle error if fetching devices fails
      print('Failed to fetch devices: $error');
    }
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
                  if (_devices.isNotEmpty)
                    DevicesListView(
                      mqttClient: widget.mqttClient,
                      devices: _devices,
                    )
                  else
                    const Center(
                        child:
                            CircularProgressIndicator()), // Show a loading indicator while fetching devices
                  // Content for Tab 2
                  if (_devices.isNotEmpty)
                    DevicesMapView(
                      mqttClient: widget.mqttClient,
                      devices: _devices,
                    )
                  else
                    const Center(
                        child:
                            CircularProgressIndicator()), // Show a loading indicator while fetching devices
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

void _clearSearch() {
    // Clear the search query
    _searchController.clear();
    // Call filterMissions with an empty string to reset the filtered list
    _filterDevices('');
  }
  void _filterDevices(String query) {
    // Implement device filtering logic here
  }
}
