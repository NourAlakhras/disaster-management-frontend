import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/screens/admin/device_profile.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_search_bar.dart';
import 'package:flutter_3/widgets/filter_drawer.dart';

class DevicesListView extends StatefulWidget {
  final MQTTClientWrapper mqttClient;

  const DevicesListView({
    super.key,
    required this.mqttClient,
  });

  @override
  State<DevicesListView> createState() => _DevicesListViewState();
}

class _DevicesListViewState extends State<DevicesListView> {
  List<Device> _allDevices = [];
  List<Device> _filteredDevices = [];
  bool _isLoading = false;
  int _pageNumber = 1;
  final int _pageSize = 6;
  final TextEditingController _searchController = TextEditingController();
  List<DeviceStatus>? _filteredStatuses = DeviceStatus.values;
  List<DeviceType>? _filteredTypes = DeviceType.values;
  String? _name;
  final criteriaList = [
    FilterCriterion(
        name: 'Device Status', options: DeviceStatus.values.toList()),
    FilterCriterion(name: 'Device Type', options: DeviceType.values.toList()),
  ];
  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices({
    List<DeviceStatus>? statuses,
    List<DeviceType>? types,
    int? pageNumber,
    int? pageSize,
    String? name,
  }) async {
    // Assign default statuses if not provided
    statuses ??= _filteredStatuses;
    types ??= _filteredTypes;
    pageNumber ??= _pageNumber;
    pageSize ??= _pageSize;
    name ??= _name;
    setState(() {
      _isLoading = true;
    });
    try {
      final devices = await DeviceApiService.getAllDevices(
        pageNumber: _pageNumber,
        pageSize: _pageSize,
        types: types,
        statuses: statuses,
        name: name,
      );
      setState(() {
        _allDevices = devices;
        _filteredDevices = _allDevices;
      });
    } catch (error) {
      print('Failed to fetch devices: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121417),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15.0, 00),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
              child: CustomSearchBar(
                controller: _searchController,
                onChanged: _filterDevices,
                onClear: _clearSearch,
              ),
            ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_filteredDevices.isEmpty)
              const Center(
                child: Text(
                  'No devices available',
                  style: TextStyle(color: Colors.white),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Labels Row
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey),
                          ),
                        ),
                        height: 60,
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text('Device Name',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white)),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('Status',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white)), // Light text color
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('Type',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white)), // Light text color
                            ),
                            Expanded(
                              flex: 2,
                              child:
                                  SizedBox(), // Placeholder for actions column
                            ),
                          ],
                        ),
                      ),
                      // Device Rows
                      ..._filteredDevices.map((device) {
                        print(device.device_id);

                        return InkWell(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DeviceProfileScreen(
                                    device: device,
                                    mqttClient: widget.mqttClient),
                              )),
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                color: Color(0xff293038),
                              )),
                            ),
                            height: 70,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Text(device.name,
                                      style: const TextStyle(
                                          fontSize: 17,
                                          color: Colors
                                              .white70)), // Light text color
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                      device.status
                                          .toString()
                                          .split('.')
                                          .last
                                          .toLowerCase(),
                                      style: const TextStyle(
                                          fontSize: 17,
                                          color: Colors
                                              .white70)), // Light text color
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                      device.type
                                          .toString()
                                          .split('.')
                                          .last
                                          .toLowerCase(),
                                      style: const TextStyle(
                                          fontSize: 17,
                                          color: Colors
                                              .white70)), // Light text color
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: _buildDeviceActions(device),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10.0, 20, 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _pageNumber > 1 ? _previousPage : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white70,
                      elevation: 0, // No shadow
                      shape: const CircleBorder(), // Circular button shape
                    ),
                    child: const Text('<'),
                  ),
                  ElevatedButton(
                    onPressed:
                        _allDevices.length > _pageSize ? _nextPage : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white70,
                      elevation: 0, // No shadow
                      shape: const CircleBorder(), // Circular button shape
                    ),
                    child: const Text('>'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      endDrawer: FilterDrawerWidget(
        onFilterApplied: (selectedCriteria) {
          final List<DeviceStatus> selectedStatuses =
              (selectedCriteria['Device Status'] as List<dynamic>)
                  .cast<DeviceStatus>();
          final List<DeviceType> selectedTypes =
              (selectedCriteria['Device Type'] as List<dynamic>)
                  .cast<DeviceType>();

          if (selectedStatuses.isNotEmpty) {
            setState(() {
              _filteredStatuses = selectedStatuses;
              _filteredTypes = selectedTypes;
            });
          } else if (selectedTypes.isNotEmpty) {
            setState(() {
              _filteredTypes = selectedTypes;
            });
          } else {
            //both are empty
            _filteredStatuses = DeviceStatus.values
                .where((status) => status != DeviceStatus.INACTIVE)
                .toList();
            _filteredTypes = DeviceType.values;
          }

          setState(() {
            _pageNumber = 1;
          });
          _fetchDevices();
        },
        criteriaList: criteriaList,
        title: 'Filter Options',
      ),
    );
  }

  void _filterDevices(String name) {
    if (name.isNotEmpty) {
      // Call fetch devices with the search query
      setState(() {
        _name = name;
      });
    } else {
      // If query is empty, fetch all devices
      _fetchDevices();
    }

    setState(() {
      _pageNumber = 1;
    });
    _fetchDevices();
  }

  Future<void> _previousPage() async {
    if (_pageNumber > 1) {
      setState(() {
        _pageNumber--;
      });
      await _fetchDevices();
    }
  }

  Future<void> _nextPage() async {
    setState(() {
      _pageNumber++;
    });
    await _fetchDevices();
  }

  List<Widget> _buildDeviceActions(Device device) {
    return (device.status != DeviceStatus.INACTIVE)
        ? [
            PopupMenuButton<int>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 1,
                  child: Text('Delete'),
                ),
              ],
              onSelected: (value) {
                if (value == 1) {
                  _deleteDevice(device.device_id);
                }
              },
            )
          ]
        : [];
  }

  void _deleteDevice(String id) {}

  void _clearSearch() {
    // Clear the search query
    _searchController.clear();
    setState(() {
      _name = '';
      _pageNumber = 1;
    });
    _fetchDevices();

    // Call filterDevices with an empty string to reset the filtered list
    _filterDevices('');
  }
}
