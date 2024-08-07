import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/models/user_credentials.dart';
import 'package:flutter_3/screens/create_mission_screen.dart';
import 'package:flutter_3/screens/mission_profile.dart';
import 'package:flutter_3/screens/settings_screen.dart';
import 'package:flutter_3/services/api_services/mission_api_service.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/services/api_services/user_api_service.dart';
import 'package:flutter_3/widgets/custom_search_bar.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/filter_drawer.dart';
import 'package:flutter_3/utils/app_colors.dart';

class MissionsListScreen extends StatefulWidget {
  const MissionsListScreen({super.key});

  @override
  _MissionsListScreenState createState() => _MissionsListScreenState();
}

class _MissionsListScreenState extends State<MissionsListScreen>
    with SingleTickerProviderStateMixin {
  final mqttClient = MQTTClientWrapper();

  List<Mission> _filteredMissions = [];
  int _pageNumberAllMissions = 1;
  int _pageNumberMyMissions = 1;
  bool _isLoading = false;
  final int _pageSize = 5;
  final TextEditingController _searchController = TextEditingController();
  List<MissionStatus>? _filteredstatuses = MissionStatus.values
      .where((status) =>
          status != MissionStatus.CANCELLED && status != MissionStatus.FINISHED)
      .toList();
  String? _name;
  late TabController _tabController;

  final criteriaList = UserCredentials().getUserType() == UserType.ADMIN
      ? [
          FilterCriterion(
              name: 'Mission Status', options: MissionStatus.values.toList()),
        ]
      : [
          FilterCriterion(
              name: 'Mission Status',
              options: MissionStatus.values
                  .where((status) =>
                      status != MissionStatus.CANCELLED &&
                      status != MissionStatus.FINISHED)
                  .toList()),
        ];

  bool _hasNext = false;
  bool _hasPrev = false;

  @override
  void initState() {
    super.initState();
    if (UserCredentials().getUserType() == UserType.ADMIN) {
      _tabController = TabController(length: 2, vsync: this);
      _tabController.addListener(_onTabChanged);
    }
    _fetchMissions();
  }

  void _onTabChanged() {
    setState(() {
      _pageNumberAllMissions = 1;
      _pageNumberMyMissions = 1;
    });
    _fetchMissions();
  }

  Future<void> _fetchMissions({
    List<MissionStatus>? statuses,
    int? pageSize,
    String? name,
  }) async {
    pageSize ??= _pageSize;
    statuses ??= _filteredstatuses;
    name ??= _name;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });
    try {
      final missionResponse = UserCredentials().getUserType() == UserType.ADMIN
          ? (_tabController.index == 0
              ? await MissionApiService.getAllMissions(
                  context: context,
                  pageNumber: _pageNumberAllMissions,
                  pageSize: pageSize,
                  statuses: statuses,
                  name: name,
                )
              : await UserApiService.getCurrentMissions(
                  context: context,
                  pageNumber: _pageNumberMyMissions,
                  pageSize: pageSize,
                  statuses: statuses,
                  name: name,
                ))
          : await UserApiService.getCurrentMissions(
              context: context,
              pageNumber: _pageNumberMyMissions,
              pageSize: pageSize,
              statuses: statuses,
              name: name,
            );
      setState(() {
        _filteredMissions = missionResponse.items;
        _hasNext = missionResponse.hasNext;
        _hasPrev = missionResponse.hasPrev;
      });
    } catch (error) {
      print('Failed to fetch missions: $error');
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
        title: "Missions' List",
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
          }),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: primaryTextColor,
            onPressed: () {},
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(15, 8, 15.0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomSearchBar(
              controller: _searchController,
              onChanged: _filterMissions,
              onClear: _clearSearch,
            ),
            if (UserCredentials().getUserType() == UserType.ADMIN)
              TabBar(
                labelColor: primaryTextColor,
                unselectedLabelColor: secondaryTextColor,
                indicator: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: accentColor,
                      width: 5.0,
                    ),
                  ),
                ),
                controller: _tabController,
                tabs: const [
                  Tab(
                    child: SizedBox.expand(
                      child: Center(
                        child: Text('All Missions'),
                      ),
                    ),
                  ),
                  Tab(
                    child: SizedBox.expand(
                      child: Center(
                        child: Text('My Missions'),
                      ),
                    ),
                  ),
                ],
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredMissions.isEmpty
                      ? const Center(
                          child: Text(
                            'No missions available',
                            style: TextStyle(color: primaryTextColor),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(
                                height: 10,
                              ),
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
                                      child: Text('Mission Name',
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
                                              color: primaryTextColor)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: SizedBox(),
                                    ),
                                  ],
                                ),
                              ),
                              ..._filteredMissions.map((mission) {
                                return InkWell(
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MissionProfileScreen(
                                          mission: mission,
                                        ),
                                      )).then((_) {
                                    setState(() {
                                      _fetchMissions();
                                    });
                                  }),
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
                                          child: Text(mission.name,
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  color: secondaryTextColor)),
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
                                                  fontSize: 15,
                                                  color: secondaryTextColor)),
                                        ),
                                        Expanded(
                                          flex: 2,
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
                      elevation: 0,
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(Icons.arrow_back),
                  ),
                  Container(
                    decoration: UserCredentials().getUserType() ==
                            UserType.ADMIN
                        ? BoxDecoration(
                            // ignore: prefer_const_constructors
                            gradient: LinearGradient(
                              // ignore: prefer_const_literals_to_create_immutables
                              colors: [cardColor, accentColor],
                            ),
                            borderRadius:
                                BorderRadius.circular(50), // Adjust as needed
                            boxShadow: [
                              BoxShadow(
                                color: barColor.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          )
                        : const BoxDecoration(), // Empty BoxDecoration for non-admins
                    child: UserCredentials().getUserType() == UserType.ADMIN
                        ? ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateMissionScreen(),
                                ),
                              ).then((_) {
                                setState(() {
                                  _fetchMissions();
                                });
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors
                                  .transparent, // Remove default background
                              padding: const EdgeInsets.all(20),
                              shape: const CircleBorder(),
                              elevation:
                                  0, // No elevation as it's handled by BoxDecoration
                            ),
                            child:
                                const Icon(Icons.add, color: primaryTextColor),
                          )
                        : const SizedBox(), // Empty SizedBox for non-admins
                  ),
                  ElevatedButton(
                    onPressed: _hasNext ? _nextPage : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: accentColor,
                      backgroundColor: secondaryTextColor,
                      elevation: 0,
                      shape: const CircleBorder(),
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
            _pageNumberAllMissions = 1;
            _pageNumberMyMissions = 1;
          });
          _fetchMissions();
        },
        criteriaList: criteriaList,
        title: 'Filter Options',
      ),
    );
  }

  void _filterMissions(String name) {
    setState(() {
      _name = name.isNotEmpty ? name : '';
      _pageNumberAllMissions = 1;
      _pageNumberMyMissions = 1;
    });
    _fetchMissions();
  }

  Future<void> _previousPage() async {
    if (_tabController.index == 0) {
      if (_pageNumberAllMissions > 1) {
        setState(() {
          _pageNumberAllMissions--;
        });
      }
      await _fetchMissions();
    } else {
      if (_pageNumberMyMissions > 1) {
        setState(() {
          _pageNumberMyMissions--;
        });
      }
      await _fetchMissions();
    }
  }

  Future<void> _nextPage() async {
    if (_tabController.index == 0) {
      setState(() {
        _pageNumberAllMissions++;
      });
    } else {
      setState(() {
        _pageNumberMyMissions++;
      });
    }
    await _fetchMissions();
  }

  List<Widget> _buildMissionActions(Mission mission) {
    if (UserCredentials().getUserType() != UserType.ADMIN) {
      return [];
    }

    switch (mission.status) {
      case MissionStatus.CREATED:
        return [
          _buildPopupMenuButton(
            items: [
              _buildPopupMenuItem(1, 'Start'),
              _buildPopupMenuItem(2, 'Cancel'),
            ],
            onSelected: (value) async {
              if (value == 1) {
                await mission.start(
                    updateState: () {
                      setState(() {});
                    },
                    context: context);
              } else if (value == 2) {
                await mission.cancel(
                    updateState: () {
                      setState(() {});
                    },
                    context: context);
              }
              setState(() {});
            },
          ),
        ];

      case MissionStatus.ONGOING:
        return [
          _buildPopupMenuButton(
            items: [
              _buildPopupMenuItem(1, 'Pause'),
              _buildPopupMenuItem(2, 'End'),
            ],
            onSelected: (value) async {
              if (value == 1) {
                await mission.pause(
                    updateState: () {
                      setState(() {});
                    },
                    context: context);
              } else if (value == 2) {
                await mission.end(
                    updateState: () {
                      setState(() {});
                    },
                    context: context);
              }
              setState(() {});
            },
          ),
        ];

      case MissionStatus.PAUSED:
        return [
          _buildPopupMenuButton(
            items: [
              _buildPopupMenuItem(1, 'Resume'),
              _buildPopupMenuItem(2, 'End'),
            ],
            onSelected: (value) async {
              if (value == 1) {
                await mission.resume(
                    updateState: () {
                      setState(() {});
                    },
                    context: context);
              } else if (value == 2) {
                await mission.end(
                    updateState: () {
                      setState(() {});
                    },
                    context: context);
              }
              setState(() {});
            },
          ),
        ];

      default:
        return [];
    }
  }

  PopupMenuButton<int> _buildPopupMenuButton({
    required List<PopupMenuItem<int>> items,
    required void Function(int) onSelected,
  }) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert, color: secondaryTextColor),
      itemBuilder: (context) => items,
      onSelected: onSelected,
    );
  }

  PopupMenuItem<int> _buildPopupMenuItem(int value, String text) {
    return PopupMenuItem<int>(
      value: value,
      child: Text(text),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _name = '';
      _pageNumberAllMissions = 1;
      _pageNumberMyMissions = 1;
    });
    _fetchMissions();

    _filterMissions('');
  }
}
