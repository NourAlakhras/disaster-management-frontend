import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/custom_search_bar.dart';
import 'package:flutter_3/widgets/filter_drawer.dart';
import 'package:flutter_3/widgets/mission_devices_list_tab.dart';
import 'package:flutter_3/widgets/mission_devices_map_tab.dart';
import 'package:flutter_3/widgets/mission_devices_thumbnails_tab.dart';
import 'package:flutter_3/widgets/tabbed_view.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/app_colors.dart';

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
  List<DeviceType>? _filteredTypes = DeviceType.values;
  final criteriaList = [
    FilterCriterion(name: 'Device Type', options: DeviceType.values.toList()),
  ];
  String? _name;

  List<Device> _filteredDevices = [];

  @override
  void initState() {
    super.initState();
    fetchMissionDetails();
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
                  if (_filteredDevices.isNotEmpty)
                    MissionDevicesListTab(
                      mqttClient: widget.mqttClient,
                      devices: _filteredDevices,
                    )
                  else
                    const Center(
                      child: Text('No devices available',
                          style: TextStyle(color: primaryTextColor)),
                    ),
                  // Content for Tab 2
                  if (_filteredDevices.isNotEmpty)
                    MissionDevicesThumbnailsTab(
                      mqttClient: widget.mqttClient,
                      devices: _filteredDevices,
                    )
                  else
                    const Center(
                      child: Text('No devices available',
                          style: TextStyle(color: primaryTextColor)),
                    ),
                  // Content for Tab 3
                  if (_filteredDevices.isNotEmpty)
                    MissionDevicesMapTab(
                      mqttClient: widget.mqttClient,
                      devices: _filteredDevices, // Use devices from mission
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
