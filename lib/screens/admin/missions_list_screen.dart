import 'package:flutter/material.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/screens/admin/create_mission_screen.dart';
import 'package:flutter_3/screens/admin/misssion_profile.dart';
import 'package:flutter_3/screens/shared/settings_screen.dart';
import 'package:flutter_3/services/mission_api_service.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/widgets/custom_search_bar.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/filter_drawer.dart';

class MissionsListScreen extends StatefulWidget {
  final MQTTClientWrapper mqttClient;

  const MissionsListScreen({super.key, required this.mqttClient});

  @override
  _MissionsListScreenState createState() => _MissionsListScreenState();
}

class _MissionsListScreenState extends State<MissionsListScreen> {
  List<Mission> _allMissions = [];
  List<Mission> _filteredMissions = [];

  bool _isLoading = false;
  int _pageNumber = 1;
  final int _pageSize = 5;
  final TextEditingController _searchController = TextEditingController();
  List<MissionStatus>? _filteredstatuses = MissionStatus.values
      .where((status) => status != MissionStatus.CANCELED)
      .toList();
  String? _name;
  final criteriaList = [
    FilterCriterion(
        name: 'Mission Status', options: MissionStatus.values.toList()),
  ];

  @override
  void initState() {
    super.initState();
    _fetchMissions();
  }

  Future<void> _fetchMissions({
    List<MissionStatus>? statuses,
    int? pageNumber,
    int? pageSize,
    String? name,
  }) async {
    // Assign default statuses if not provided
    statuses ??= _filteredstatuses;
    pageNumber ??= _pageNumber;
    pageSize ??= _pageSize;
    name ??= _name;
    setState(() {
      _isLoading = true;
    });
    try {
      final missions = await MissionApiService.getAllMissions(
        pageNumber: _pageNumber,
        pageSize: _pageSize,
        statuses: statuses,
        name: name,
      );
      setState(() {
        _allMissions = missions;
        _filteredMissions = _allMissions;
      });
    } catch (error) {
      print('Failed to fetch missions: $error');
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
      appBar: CustomUpperBar(
        title: "Missions' List",
        leading: IconButton(
            icon: const Icon(Icons.settings),
            color: Colors.white,
            onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SettingsScreen(mqttClient: widget.mqttClient)),
                )),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: const Color.fromARGB(255, 255, 255, 255),
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
              onChanged: _filterMissions,
              onClear: _clearSearch,
            ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_filteredMissions.isEmpty)
              const Center(
                child: Text(
                  'No missions available',
                  style: TextStyle(color: Colors.white), // White text color
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
                            bottom: BorderSide(color: Colors.grey),
                          ),
                        ),
                        height: 60,
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text('Mission Name',
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
                              flex: 2,
                              child:
                                  SizedBox(), // Placeholder for actions column
                            ),
                          ],
                        ),
                      ),
                      // Mission Rows
                      ..._filteredMissions.map((mission) {
                        print(mission.id);

                        return InkWell(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MissionProfileScreen(
                                    mission: mission,
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
                                  child: Text(mission.name,
                                      style: const TextStyle(
                                          fontSize: 17,
                                          color: Colors
                                              .white70)), // Light text color
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                      mission.status
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
                                    children: _buildMissionActions(mission),
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
                    child: const Icon(Icons.arrow_back),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to the CreateMissionScreen when the button is pressed
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CreateMissionScreen()),
                      ).then((result) {
                        // Reload missions if mission creation was successful
                        if (result == true) {
                          _fetchMissions();
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white70,

                      elevation: 0, // No shadow
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                    ),
                    child: const Icon(Icons.add), // Black icon color
                  ),
                  ElevatedButton(
                    onPressed:
                        _allMissions.length > _pageSize ? _nextPage : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white70,
                      elevation: 0, // No shadow
                      shape: const CircleBorder(), // Circular button shape
                    ),
child: const Icon(Icons.arrow_forward),                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      endDrawer: FilterDrawerWidget(
        onFilterApplied: (selectedCriteria) {
          final List<MissionStatus> selectedStatuses =
              (selectedCriteria['Mission Status'] as List<dynamic>)
                  .cast<MissionStatus>();

          if (selectedStatuses.isNotEmpty) {
            setState(() {
              _filteredstatuses = selectedStatuses;
            });
          } else {
            _filteredstatuses = MissionStatus.values;
          }

          setState(() {
            _pageNumber = 1;
          });
          _fetchMissions();
        },
        criteriaList: criteriaList,
        title: 'Filter Options',
      ),
    );
  }

  void _filterMissions(String name) {
    if (name.isNotEmpty) {
      // Call fetch missions with the search query
      setState(() {
        _name = name;
      });
    } else {
      // If query is empty, fetch all missions
      _fetchMissions();
    }

    setState(() {
      _pageNumber = 1;
    });
    _fetchMissions();
  }

  Future<void> _previousPage() async {
    if (_pageNumber > 1) {
      setState(() {
        _pageNumber--;
      });
      await _fetchMissions();
    }
  }

  Future<void> _nextPage() async {
    setState(() {
      _pageNumber++;
    });
    await _fetchMissions();
  }

  List<Widget> _buildMissionActions(Mission mission) {
    switch (mission.status) {
      case MissionStatus.CREATED:
        print('mission.id ${mission.id}');
        return [
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: Text('Start'),
              ),
              const PopupMenuItem(
                value: 2,
                child: Text('Cancel'),
              ),
            ],
            onSelected: (value) {
              if (value == 1) {
                _startMission(mission.id);
              } else if (value == 2) {
                _cancelMission(mission.id);
              }
            },
          ),
        ];
      case MissionStatus.ONGOING:
        return [
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: Text('Pause'),
              ),
              const PopupMenuItem(
                value: 2,
                child: Text('End'),
              ),
            ],
            onSelected: (value) {
              if (value == 1) {
                _pauseMission(mission.id);
              } else if (value == 2) {
                _endMission(mission.id);
              }
            },
          ),
        ];
      case MissionStatus.PAUSED:
        return [
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: Text('Resume'),
              ),
              const PopupMenuItem(
                value: 2,
                child: Text('End'),
              ),
            ],
            onSelected: (value) {
              if (value == 1) {
                _resumeMission(mission.id);
              } else if (value == 2) {
                _endMission(mission.id);
              }
            },
          ),
        ];
      default:
        return [];
    }
  }

  Future<void> _startMission(String missionId) async {
    try {
      print('missionId $missionId');
      String command = "start";
      await MissionApiService.updateMissionStatus(missionId, command);
      await _fetchMissions();
    } catch (error) {
      print('Failed to start mission: $error');
    }
  }

  void _pauseMission(String missionId) async {
    try {
      print('missionId $missionId');
      String command = "pause";
      await MissionApiService.updateMissionStatus(missionId, command);
      await _fetchMissions();
    } catch (error) {
      print('Failed to pause mission: $error');
    }
  }

  void _endMission(String missionId) async {
    try {
      print('missionId $missionId');
      String command = "end";
      await MissionApiService.updateMissionStatus(missionId, command);
      await _fetchMissions();
    } catch (error) {
      print('Failed to end mission: $error');
    }
  }

  void _cancelMission(String missionId) async {
    try {
      print('missionId $missionId');
      String command = "cancel";
      await MissionApiService.updateMissionStatus(missionId, command);
      await _fetchMissions();
    } catch (error) {
      print('Failed to cancel mission: $error');
    }
  }

  void _resumeMission(String missionId) async {
    try {
      print('missionId $missionId');
      String command = "continue";
      await MissionApiService.updateMissionStatus(missionId, command);
      await _fetchMissions();
    } catch (error) {
      print('Failed to continue mission: $error');
    }
  }

  void _clearSearch() {
    // Clear the search query
    _searchController.clear();
    setState(() {
      _name = '';
      _pageNumber = 1;
    });
    _fetchMissions();

    // Call filterMissions with an empty string to reset the filtered list
    _filterMissions('');
  }
}
