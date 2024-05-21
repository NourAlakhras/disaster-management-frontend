import 'package:flutter/material.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/screens/shared/settings_screen.dart';
import 'package:flutter_3/services/admin_api_service.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/services/user_api_service.dart';
import 'package:flutter_3/widgets/custom_search_bar.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/utils/exceptions.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/filter_drawer.dart';
import 'package:flutter_3/screens/admin/user_profile.dart';

class UsersListScreen extends StatefulWidget {
  final MQTTClientWrapper mqttClient;

  const UsersListScreen({super.key, required this.mqttClient});

  @override
  _UsersListScreenState createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  bool _isLoading = false;
  int _pageNumber = 1;
  final int _pageSize = 6;
  int allUsersCount = 0;

  final TextEditingController _searchController = TextEditingController();

  List<UserStatus>? _filteredStatuses = UserStatus.values
      .where((status) => status != UserStatus.INACTIVE)
      .toList();

  List<UserType>? _filteredTypes = [
    UserType.REGULAR,
    UserType.ADMIN,
  ];
  String? _name;
  final criteriaList = [
    FilterCriterion(name: 'User Status', options: UserStatus.values.toList()),
    FilterCriterion(name: 'User Type', options: UserType.values.toList()),
  ];

  @override
  void initState() {
    super.initState();
    _fetchCounts();
    _fetchUsers();
  }

  Future<void> _fetchCounts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Fetch all users counts

      allUsersCount = await AdminApiService.getUserCount();
    } catch (e) {
      // Handle error
      print('Error fetching counts: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchUsers({
    List<UserStatus>? statuses,
    List<UserType>? types,
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
      print('from fetch: $statuses');
      final allUsersResponse = await AdminApiService.getAllUsers(
        pageNumber: pageNumber,
        pageSize: pageSize,
        statuses: statuses,
        types: types,
        username: name,
      );
      setState(() {
        _allUsers = allUsersResponse;
        _filteredUsers = _allUsers;
      });
    } catch (error) {
      print('Failed to fetch users: $error');
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
        title: "Users' List",
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
              onChanged: _filterUsers,
              onClear: _clearSearch,
            ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_filteredUsers.isEmpty)
              const Center(
                child: Text(
                  'No users available',
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
                        height: 20,
                      ),
                      // Labels Row
                      Container(
                        decoration: const BoxDecoration(
                            border: Border(
                          bottom: BorderSide(color: Colors.grey),
                        )),
                        height: 60,
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text('Username',
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
                                      color: Colors.white)),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('Type',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white)),
                            ),
                            Expanded(
                              flex: 2,
                              child: SizedBox(),
                            ),
                          ],
                        ),
                      ),
                      // User Rows
                      ..._filteredUsers.map((user) {
                        return InkWell(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProfileScreen(
                                    user: user, mqttClient: widget.mqttClient),
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
                                  child: Text(
                                    user.username,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    user.status
                                        .toString()
                                        .split('.')
                                        .last
                                        .toLowerCase(),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    user.type
                                        .toString()
                                        .split('.')
                                        .last
                                        .toLowerCase(),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: _buildUserActions(user),
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
                    onPressed: allUsersCount > _pageSize&& _pageNumber< allUsersCount/ _pageSize ? _nextPage : null,
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
          final List<UserStatus> selectedStatuses =
              (selectedCriteria['User Status'] as List<dynamic>)
                  .cast<UserStatus>();
          final List<UserType> selectedTypes =
              (selectedCriteria['User Type'] as List<dynamic>).cast<UserType>();

          if (selectedStatuses.isNotEmpty) {
            setState(() {
              _filteredStatuses = selectedStatuses;
              _filteredTypes = selectedTypes;
            });
          } else if (selectedTypes.isNotEmpty) {
            print('hi no status');
            setState(() {
              _filteredTypes = selectedTypes;
            });
          } else {
            _filteredStatuses = UserStatus.values
                .where((status) => status != UserStatus.INACTIVE)
                .toList();

            _filteredTypes = [
              UserType.REGULAR,
              UserType.ADMIN,
            ];
          }

          setState(() {
            _pageNumber = 1;
          });
          _fetchUsers();
        },
        criteriaList: criteriaList,
        title: 'Filter Options',
      ),
    );
  }

  void _filterUsers(String name) {
    if (name.isNotEmpty) {
      // Call fetch missions with the search query
      setState(() {
        _name = name;
      });
    } else {
      // If query is empty, fetch all missions
      _fetchUsers();
    }

    setState(() {
      _pageNumber = 1;
    });
    _fetchUsers();
  }

  Future<void> _approveUser(String userId, {required bool isAdmin}) async {
    try {
      // Call the API to approve the user account
      await AdminApiService.approveUser(userId, isAdmin);
      // After successful approval, refresh the user list
      await _fetchUsers();
    } catch (error) {
      print('Failed to approve user: $error');
    }
  }

  Future<void> _rejectUser(String userId) async {
    try {
      await AdminApiService.rejectUser(userId);
      await _fetchUsers();
    } catch (error) {
      print('Failed to reject user: $error');
    }
  }

  Future<void> _activateUser(User user) async {
    // Implement activating logic
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await AdminApiService.deleteUser(userId);
      await _fetchUsers();
    } catch (error) {
      print('Failed to delete user: $error');
    }
  }

  Future<List<Mission>> _getUserCurrentMissions(String userId) async {
    try {
      final List<Mission> missions =
          await UserApiService.getUserCurrentMissions(userId);
      return missions;
    } on NotFoundException {
      // Handle the case when no missions are found for the user
      print('No missions found for the user.');
      return [];
    } catch (error) {
      // Handle other errors
      print('Failed to retrieve user missions: $error');
      throw Exception('Failed to retrieve current missions: $error');
    }
  }

  // Future<void> _showUserDetailsDialog(User user) async {
  //   try {
  //     final userDetails = await AdminApiService.getUserDetails(user.user_id);
  //     final userMissions = await _getUserCurrentMissions(user.user_id);

  //     showDialog(
  //       context: context,
  //       builder: (context) {
  //         return AlertDialog(
  //           title: const Text('User Details'),
  //           content: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text('Username: ${userDetails['username']}'),
  //               Text('Email: ${userDetails['email']}'),
  //               Text(
  //                   'Type: ${user.type.toString().split('.').last.toLowerCase()}'),
  //               Text(
  //                   'Status: ${user.status.toString().split('.').last.toLowerCase()}'),
  //               const SizedBox(
  //                   height: 16), // Add space between details and buttons
  //               const Text('Current Missions:'),
  //               userMissions.isNotEmpty
  //                   ? Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: userMissions
  //                           .map((mission) => Text('- ${mission.name}'))
  //                           .toList(),
  //                     )
  //                   : const Text('No missions available.'),
  //               const SizedBox(
  //                   height: 16), // Add space between missions and buttons
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.end,
  //                 children: _buildUserActionsForDetails(user),
  //               ),
  //             ],
  //           ),
  //         );
  //       },
  //     );
  //   } catch (error) {
  //     print('Failed to load user details: $error');
  //     // Handle error
  //   }
  // }

  List<Widget> _buildUserActionsForDetails(User user) {
    if (user.status == UserStatus.PENDING) {
      return [
        ElevatedButton(
          onPressed: () {
            _showApprovalDialog(user.user_id);
          },
          child: const Text('Approve'),
        ),
        ElevatedButton(
          onPressed: () {
            _rejectUser(user.user_id);
          },
          child: const Text('Reject'),
        ),
        ElevatedButton(
          onPressed: () {
            _deleteUser(user.user_id);
          },
          child: const Text('Delete'),
        ),
      ];
    } else if (user.status == UserStatus.REJECTED) {
      return [
        ElevatedButton(
          onPressed: () {
            _showApprovalDialog(user.user_id);
          },
          child: const Text('Approve'),
        ),
      ];
    } else {
      return [
        ElevatedButton(
          onPressed: () {
            _deleteUser(user.user_id);
          },
          child: const Text('Delete'),
        ),
      ];
    }
  }

  Future<void> _showApprovalDialog(String userId) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Approve User'),
          content: const Text('Approve as admin or regular user?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _approveUser(userId, isAdmin: true);
              },
              child: const Text('Admin'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _approveUser(userId, isAdmin: false);
              },
              child: const Text('Regular User'),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildUserActions(User user) {
    if (user.status == UserStatus.PENDING) {
      return [
        PopupMenuButton<int>(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 1,
              child: Text('Approve'),
            ),
            const PopupMenuItem(
              value: 2,
              child: Text('Reject'),
            ),
            const PopupMenuItem(
              value: 3,
              child: Text('Delete'),
            ),
          ],
          onSelected: (value) {
            if (value == 1) {
              _showApprovalDialog(user.user_id);
            } else if (value == 2) {
              _rejectUser(user.user_id);
            } else if (value == 3) {
              _deleteUser(user.user_id);
            }
          },
        ),
      ];
    } else if (user.status == UserStatus.REJECTED) {
      return [
        PopupMenuButton<int>(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 1,
              child: Text('Approve'),
            ),
          ],
          onSelected: (value) {
            if (value == 1) {
              _showApprovalDialog(user.user_id);
            }
          },
        ),
      ];
    } else if (user.status == UserStatus.INACTIVE) {
      return [];
    } else {
      return [
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
              _deleteUser(user.user_id);
            }
          },
        ),
      ];
    }
  }

  Future<void> _previousPage() async {
    if (_pageNumber > 1) {
      setState(() {
        _pageNumber--;
      });
      await _fetchUsers();
    }
  }

  Future<void> _nextPage() async {
    setState(() {
      _pageNumber++;
    });
    await _fetchUsers();
  }

  void _clearSearch() {
    // Clear the search query
    _searchController.clear();
    setState(() {
      _name = '';
      _pageNumber = 1;
    });
    _fetchUsers();
    _filterUsers('');
  }
}
