import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/screens/user/device_detailed_screen.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_search_bar.dart';
import 'package:flutter_3/widgets/filter_drawer.dart';

class DevicesThumbnailsView extends StatefulWidget {
  final MQTTClientWrapper mqttClient;
  final List<Mission>? passedMissions; // pass mission to show its devices TBD
  const DevicesThumbnailsView({
    super.key,
    required this.mqttClient,
    this.passedMissions
  });
  @override
  State<DevicesThumbnailsView> createState() => _DevicesThumbnailsViewState();
}

class _DevicesThumbnailsViewState extends State<DevicesThumbnailsView> {
  List<Device> _allDevices = [];
  List<Device> _filteredDevices = [];
  bool _isLoading = false;
  int _pageNumber = 1;
  final int _pageSize = 6;
  final TextEditingController _searchController = TextEditingController();
  final List<DeviceStatus> _filteredStatuses = [
    DeviceStatus.ASSIGNED,
  ];
  List<DeviceType>? _filteredTypes = DeviceType.values;
  String? _name;
  final criteriaList = [
    FilterCriterion(name: 'Device Type', options: DeviceType.values.toList()),
  ];

  Map<String, int> batteryLevels = {}; // Store battery levels for each device
  Map<String, int> wifiLevels = {}; // Store Wi-Fi levels for each device

  @override
  void initState() {
    super.initState();
    _fetchDevices();
    _subscribeToTopics();
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

  void _subscribeToTopics() {
    for (var device in _filteredDevices) {
      List<String> mqttTopics = [
        '${device.device_id}/battery',
        '${device.device_id}/connectivity',
      ];

      widget.mqttClient.subscribeToMultipleTopics(mqttTopics);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get half of the screen width
    double screenWidth = (MediaQuery.of(context).size.width) / 2;
    print('screenWidth $screenWidth');

    double aspectRatio = 16 / 9;

    // Calculate the height based on the aspect ratio
    double videoHeight = screenWidth / aspectRatio;
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
                child: ListView.builder(
                  itemCount: _filteredDevices.length,
                  itemBuilder: (context, index) {
                    Device device = _filteredDevices[index];
                    List<String> mqttTopics = [
                      '${device.device_id}/battery',
                      '${device.device_id}/connectivity',
                    ];
                    widget.mqttClient.subscribeToMultipleTopics(mqttTopics);
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeviceDetailedScreen(
                              mqttClient: widget.mqttClient,
                              device: device,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 0),
                        decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                            color: Color(0xff293038),
                          )),
                        ),
                        child: Container(
                          color: Colors.transparent,
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        device.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        device.type
                                            .toString()
                                            .split('.')
                                            .last
                                            .toLowerCase(),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Battery: ${batteryLevels[device.device_id] ?? '5'}%',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'WI-FI: ${wifiLevels[device.device_id] ?? '30'}%',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Container(
                                  width: screenWidth,
                                  height: videoHeight,
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: Icon(
                                      Icons.video_library,
                                      size: 100,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
          final List<DeviceType> selectedTypes =
              (selectedCriteria['Device Type'] as List<dynamic>)
                  .cast<DeviceType>();

          if (selectedTypes.isNotEmpty) {
            setState(() {
              _filteredTypes = selectedTypes;
            });
          } else {
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

  @override
  void dispose() {
    for (var device in _filteredDevices) {
      List<String> mqttTopics = [
        '${device.device_id}/battery',
        '${device.device_id}/connectivity',
      ];
      widget.mqttClient.unsubscribeFromMultipleTopics(mqttTopics);
    }
    super.dispose();
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
