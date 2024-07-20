import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/screens/device_profile.dart';
import 'package:flutter_3/screens/settings_screen.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_search_bar.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/filter_drawer.dart';
import 'package:flutter_3/utils/app_colors.dart';

class DevicesListScreen extends StatefulWidget {
  const DevicesListScreen({
    super.key,
  });

  @override
  State<DevicesListScreen> createState() => _DevicesListScreenState();
}

class _DevicesListScreenState extends State<DevicesListScreen> {
  final mqttClient = MQTTClientWrapper();

  List<Device> _allDevices = [];
  List<Device> _filteredDevices = [];
  bool _isLoading = false;
  int _pageNumber = 1;
  final int _pageSize = 6;
  bool _hasNext = false;
  bool _hasPrev = false;

  final TextEditingController _searchController = TextEditingController();
  List<DeviceStatus>? _filteredStatuses = DeviceStatus.values
      .where((status) => status != DeviceStatus.INACTIVE)
      .toList();
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

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final deviceResponse = await DeviceApiService.getAllDevices(
        pageNumber: _pageNumber,
        pageSize: _pageSize,
        types: types,
        statuses: statuses,
        name: name,
        context: context,
      );
      setState(() {
        _filteredDevices = deviceResponse.items;
        _hasNext = deviceResponse.hasNext;
        _hasPrev = deviceResponse.hasPrev;
      });
    } catch (error) {
      print('Failed to fetch devices: $error');
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomUpperBar(
        title: 'Devices',
        leading: IconButton(
            icon: const Icon(Icons.settings),
            color: primaryTextColor,
            onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                ).then((_) {
                  setState(() {
                    // Call setState to refresh the page.
                  });
                })),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: primaryTextColor,
            onPressed: () {},
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(15, 8, 15.0, 00),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomSearchBar(
              controller: _searchController,
              onChanged: _filterDevices,
              onClear: _clearSearch,
            ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_filteredDevices.isEmpty)
              const Center(
                child: Text(
                  'No devices available',
                  style: TextStyle(color: primaryTextColor),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      // Labels Row
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: accentColor),
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
                                      color: primaryTextColor)),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('Status',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color:
                                          primaryTextColor)), // Light text color
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('Type',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color:
                                          primaryTextColor)), // Light text color
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

                        Object? result;
                        return InkWell(
                          onTap: () async => {
                            result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DeviceProfileScreen(
                                    device: device,
                                  ),
                                )),
                            if (result == true)
                              {
                                // Refresh your data here
                                setState(() {
                                  _fetchDevices();
                                })
                              }
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                color: barColor,
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
                                          color:
                                              secondaryTextColor)), // Light text color
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
                                          color:
                                              secondaryTextColor)), // Light text color
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
                                          color:
                                              secondaryTextColor)), // Light text color
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
                    onPressed: _hasPrev ? _previousPage : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: accentColor,
                      backgroundColor: secondaryTextColor,
                      elevation: 0, // No shadow
                      shape: const CircleBorder(), // Circular button shape
                    ),
                    child: const Icon(Icons.arrow_back),
                  ),
                  ElevatedButton(
                    onPressed: _hasNext ? _nextPage : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: accentColor,
                      backgroundColor: secondaryTextColor,
                      elevation: 0, // No shadow
                      shape: const CircleBorder(), // Circular button shape
                    ),
                    child: const Icon(Icons.arrow_forward),
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
    setState(() {
      _name = name.isNotEmpty ? name : '';
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
              icon: const Icon(Icons.more_vert, color: secondaryTextColor),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 1,
                  child: Text('Delete'),
                ),
              ],
              onSelected: (value) {
                if (value == 1) {
                  _deleteDevice(device);
                }
              },
            )
          ]
        : [];
  }

  void _deleteDevice(Device device) {
    if (device.type == DeviceType.BROKER &&
        device.status == DeviceStatus.ASSIGNED) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You're not allowed to delete an assigned broker"),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    DeviceApiService.deleteDevice(context: context, deviceId: device.device_id)
        .then((deletedDevice) {
      _fetchDevices(); // Fetch the updated list of devices
    }).catchError((error) {
      print('Failed to delete device: $error');
    });
  }

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
