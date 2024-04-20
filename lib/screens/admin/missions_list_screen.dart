import 'package:flutter/material.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/screens/admin/create_mission_screen.dart';
import 'package:flutter_3/services/mission_api_service.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/create_mission_dialog.dart';
import 'package:flutter_3/utils/enums.dart';

class MissionsListScreen extends StatefulWidget {
  @override
  _MissionsListScreenState createState() => _MissionsListScreenState();
}

class _MissionsListScreenState extends State<MissionsListScreen> {
  List<Mission> _allMisssions = [];
  List<Mission> _filteredMisssions = [];
  bool _isLoading = false;
  int _pageNumber = 1;
  final int _pageSize = 7;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMissions();
  }

  Future<void> _fetchMissions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final missions = await MissionApiService.getAllMissions(
        pageNumber: _pageNumber,
        pageSize: _pageSize,
      );
      setState(() {
        _allMisssions = missions;
        _filteredMisssions = _allMisssions;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: const Color.fromARGB(255, 255, 255, 255),
            onPressed: () {},
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredMisssions.isEmpty
              ? const Center(
                  child: Text(
                    'No missions available',
                    style: TextStyle(color: Colors.white), // White text color
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterMissions,
                        decoration: const InputDecoration(
                          labelText: 'Search',
                          hintText: 'Search missions by name',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    // Add statistics cards here if needed
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
                              child: const Padding(
                                padding: EdgeInsets.fromLTRB(8.0, 0, 0.0, 0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text('Mission Name',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white70)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('Status',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors
                                                  .white70)), // Light text color
                                    ),
                                    Expanded(
                                      child:
                                          SizedBox(), // Placeholder for actions column
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Mission Rows
                            ..._filteredMisssions.map((mission) {
                              return Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey),
                                  ),
                                ),
                                height: 55,
                                child: InkWell(
                                  onTap: () => _showMissionDetailsDialog(mission),

                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        8.0, 8.0, 0.0, 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(mission.name,
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors
                                                      .white70)), // Light text color
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                              mission.status
                                                  .toString()
                                                  .split('.')
                                                  .last,
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors
                                                      .white70)), // Light text color
                                        ),
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            mainAxisSize: MainAxisSize.min,
                                            children:
                                                _buildMissionActions(mission),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the CreateMissionScreen when the FAB is pressed
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateMissionScreen()),
          ).then((result) {
            // Reload missions if mission creation was successful
            if (result == true) {
              _fetchMissions();
            }
          });
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.white, // White background color
        foregroundColor: Colors.black, // Black icon color
      ),
    );
  }

  void _filterMissions(String query) {
    setState(() {
      if (query.isNotEmpty) {
        _filteredMisssions = _allMisssions
            .where((mission) =>
                mission.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else {
        _filteredMisssions = _allMisssions;
      }
    });
  }

  List<Widget> _buildMissionActions(Mission mission) {
    switch (mission.status) {
      case MissionStatus.CREATED:
        return [
          PopupMenuButton<int>(
            icon: const Icon(
              Icons.more_vert,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: Text('Start'),
              ),
              const PopupMenuItem(
                value: 2,
                child: Text('Delete'),
              ),
            ],
            onSelected: (value) {
              if (value == 1) {
                _startMission(mission);
              } else if (value == 2) {
                _deleteMission(mission);
              }
            },
          ),
        ];
      case MissionStatus.ONGOING:
        return [
          PopupMenuButton<int>(
            icon: const Icon(
              Icons.more_vert,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: Text('Pause'),
              ),
              const PopupMenuItem(
                value: 2,
                child: Text('End'),
              ),
              const PopupMenuItem(
                value: 3,
                child: Text('Delete'),
              ),
            ],
            onSelected: (value) {
              if (value == 1) {
                _pauseMission(mission);
              } else if (value == 2) {
                _endMission(mission);
              } else if (value == 3) {
                _deleteMission(mission);
              }
            },
          ),
        ];
      case MissionStatus.PAUSED:
        return [
          PopupMenuButton<int>(
            icon: const Icon(
              Icons.more_vert,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: Text('Resume'),
              ),
              const PopupMenuItem(
                value: 2,
                child: Text('End'),
              ),
              const PopupMenuItem(
                value: 3,
                child: Text('Delete'),
              ),
            ],
            onSelected: (value) {
              if (value == 1) {
                _resumeMission(mission);
              } else if (value == 2) {
                _endMission(mission);
              } else if (value == 3) {
                _deleteMission(mission);
              }
            },
          ),
        ];
      case MissionStatus.FINISHED:
        return [
          PopupMenuButton<int>(
            icon: const Icon(
              Icons.more_vert,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: Text('Delete'),
              ),
            ],
            onSelected: (value) {
              if (value == 1) {
                _deleteMission(mission);
              }
            },
          ),
        ];
      default:
        return [];
    }
  }

  void _startMission(Mission mission) {}
  
  void _pauseMission(Mission mission) {}
  
  void _endMission(Mission mission) {}

  void _deleteMission(Mission mission) {}

  void _resumeMission(Mission mission) {}
  
  _showMissionDetailsDialog(Mission mission) {}
}
