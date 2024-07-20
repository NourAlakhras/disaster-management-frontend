import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/models/sensor_data.dart';
import 'package:flutter_3/providers/sensor_data_provider.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/custom_search_bar.dart';
import 'package:flutter_3/widgets/filter_drawer.dart';
import 'package:flutter_3/widgets/mission_analytics_tab.dart';
import 'package:flutter_3/widgets/mission_devices_list_tab.dart';
import 'package:flutter_3/widgets/mission_devices_map_tab.dart';
import 'package:flutter_3/widgets/mission_devices_thumbnails_tab.dart';
import 'package:flutter_3/widgets/tabbed_view.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/app_colors.dart';
import 'package:provider/provider.dart';

class MissionDevicesBaseScreen extends StatefulWidget {
  final Mission mission;

  const MissionDevicesBaseScreen({super.key, required this.mission});

  @override
  State<MissionDevicesBaseScreen> createState() =>
      _MissionDevicesBaseScreenState();
}

class _MissionDevicesBaseScreenState extends State<MissionDevicesBaseScreen> {
  final mqttClient = MQTTClientWrapper();

  final TextEditingController _searchController = TextEditingController();
  List<DeviceType>? _filteredTypes = DeviceType.values;
  final criteriaList = [
    FilterCriterion(name: 'Device Type', options: DeviceType.values.toList()),
  ];
  String? _name;
  List<String> mqttTopics = [];
  List<Device> _filteredDevices = [];
  @override
  void initState() {
    super.initState();
    fetchMissionDetails();
    mqttClient.onDataReceived = _onDataReceived; // Set the callback

    _subscribeToTopics();
  }

  void _subscribeToTopics() {

    for (var device in _filteredDevices) {
      mqttTopics.addAll([
        'cloud/reg/${widget.mission.broker?.name}/${device.name}/sensor-data',
        'cloud/reg/${widget.mission.broker?.name}/${device.name}/gps',
        'cloud/reg/${widget.mission.broker?.name}/${device.name}/connectivity',
      ]);
    }
    mqttClient.subscribeToMultipleTopics(mqttTopics);
    mqttClient.setupMessageListener();
  }

  void _unsubscribeFromTopics() {
    mqttClient.unsubscribeFromMultipleTopics(mqttTopics);
  }

  void _onDataReceived(Map<String, dynamic> data) {
    if (mounted) {
      print('Data received: $data'); // Log the entire data map

      final sensorDataProvider =
          Provider.of<SensorDataProvider>(context, listen: false);
      final topic = data['topic'] as String;

      data['topic'] = topic;
      sensorDataProvider.handleIncomingData(
          _extractDeviceNameFromTopic(topic), data);
    }
  }

  String _extractDeviceNameFromTopic(String topic) {
    final parts = topic.split('/');
    final deviceName = parts.length > 3 ? parts[3] : 'unknown_device';
    print(
        'Extracted device name: $deviceName'); // Log the extracted device name
    return deviceName;
  }

  @override
  void dispose() {
    _unsubscribeFromTopics();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomUpperBar(
        title: 'Mission: ${widget.mission.name}',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: primaryTextColor,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: primaryTextColor,
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
                length: 4,
                tabs: const <Widget>[
                  Tab(
                    child: Icon(Icons.list),
                  ),
                  Tab(
                    child: Icon(Icons.analytics_outlined),
                  ),
                  Tab(
                    child: Icon(Icons.photo_camera_front),
                  ),
                  Tab(
                    icon: Icon(Icons.map_outlined),
                  ),
                ],
                tabContents: <Widget>[
                  // Content for Tab 1
                  if (_filteredDevices.isNotEmpty)
                    MissionDevicesListTab(
                      devices: _filteredDevices,
                    )
                  else
                    const Center(
                      child: Text('No devices available',
                          style: TextStyle(color: primaryTextColor)),
                    ),
                  // Content for Tab 2
                  if (_filteredDevices.isNotEmpty)
                    MissionAnalyticsTab(
                      devices: _filteredDevices,
                      broker: widget.mission.broker,
                    )
                  else
                    const Center(
                      child: Text('No devices available',
                          style: TextStyle(color: primaryTextColor)),
                    ),
                  // Content for Tab 3
                  if (_filteredDevices.isNotEmpty)
                    MissionDevicesThumbnailsTab(
                      devices: _filteredDevices,
                      broker: widget.mission.broker,
                    )
                  else
                    const Center(
                      child: Text('No devices available',
                          style: TextStyle(color: primaryTextColor)),
                    ),
                  // // Content for Tab 4
                  if (_filteredDevices.isNotEmpty)
                    MissionDevicesMapTab(
                      devices: _filteredDevices, // Use devices from mission
                      broker: widget.mission.broker,
                    )
                  else
                    const Center(
                      child: Text('No devices available',
                          style: TextStyle(color: primaryTextColor)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      endDrawer: FilterDrawerWidget(
        onFilterApplied: (selectedCriteria) {
          final List<DeviceType> selectedTypes =
              (selectedCriteria['Device Type'] as List<dynamic>)
                  .cast<DeviceType>();

          setState(() {
            _filteredTypes =
                selectedTypes.isNotEmpty ? selectedTypes : DeviceType.values;
          });
          _filterDevices(_searchController.text);
        },
        criteriaList: criteriaList,
        title: 'Filter Options',
      ),
    );
  }

  void _filterDevices(String query) {
    setState(() {
      _name = query.isNotEmpty ? query.toLowerCase() : null;
      _filteredDevices = widget.mission.devices!.where((device) {
        final deviceNameLower = device.name.toLowerCase();
        final matchesName = _name == null || deviceNameLower.contains(_name!);
        final matchesType = _filteredTypes!.contains(device.type);
        return matchesName && matchesType;
      }).toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _filterDevices('');
  }

  Future<void> fetchMissionDetails() async {
    widget.mission.fetchMissionDetails(() {
      if (mounted) {
        setState(() {
          _filteredDevices = widget.mission.devices!;
        });
      }
    });
  }
}
