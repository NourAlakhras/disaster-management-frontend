import 'package:flutter/material.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/services/admin_api_service.dart';
import 'package:flutter_3/services/user_api_service.dart';
import 'package:flutter_3/widgets/custom_search_bar.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/utils/helpers.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/utils/exceptions.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/filter_drawer.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  _UsersListScreenState createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  bool _isLoading = false;
  int _pageNumber = 1;
  final int _pageSize = 6;
  final TextEditingController _searchController = TextEditingController();
  Status? _selectedStatus;
  UserType? _selectedType;

  List<Status>? _filteredstatuses = [
    Status.AVAILABLE,
    Status.PENDING,
    Status.ASSIGNED,
    Status.REJECTED,
  ];

  List<UserType>? _filteredtypes = [
    UserType.REGULAR,
    UserType.ADMIN,
  ];
  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers({
    List<Status>? statuses,
    List<UserType>? types,
    int? pageNumber,
    int? pageSize,
  }) async {
    // Assign default statuses if not provided
    statuses ??= _filteredstatuses;
    types ??= _filteredtypes;
    pageNumber ??= _pageNumber;
    pageSize ??= _pageSize;

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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(15, 8, 15.0, 00),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomSearchBar(
              controller: _searchController,
              onChanged: _filterUsers,
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
                          border:
                              Border(bottom: BorderSide(color: Colors.grey)),
                        ),
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
                              child: Text('Type',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color:
                                          Colors.white)), // Light text color),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('Status',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color:
                                          Colors.white)), // Light text color),
                            ),
                            Expanded(
                              flex: 2,
                              child:
                                  SizedBox(), // Placeholder for actions column
                            ),
                          ],
                        ),
                      ),
                      // User Rows
                      ..._filteredUsers.map((user) {
                        return InkWell(
                          onTap: () => _showUserDetailsDialog(user),
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: Colors.grey)),
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
                                    statusToString(user.status),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    userTypeToString(user.type),
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
                    child: const Text('<'),
                  ),
                  ElevatedButton(
                    onPressed: _allUsers.length >= _pageSize ? _nextPage : null,
                    child: const Text('>'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      endDrawer: FilterDrawerWidget(
        onFilterApplied: (selectedStatuses, selectedTypes) {
          if (selectedStatuses.isNotEmpty) {
            setState(() {
              _filteredstatuses = selectedStatuses;
              _filteredtypes = selectedTypes;
              _pageNumber = 1;
            });
            _fetchUsers();
          }
        },
      ),
    );
  }

  int _getActiveUsersCount() {
    return _allUsers
        .where((user) =>
            user.status != Status.INACTIVE && user.status != Status.REJECTED)
        .length;
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isNotEmpty) {
        _filteredUsers = _allUsers
            .where((user) =>
                user.username.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else {
        _filteredUsers = _allUsers;
      }
    });
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

  Future<void> _editUser(User user) async {
    // Implement editing logic
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

  Future<void> _showUserDetailsDialog(User user) async {
    try {
      final userDetails = await AdminApiService.getUserDetails(user.id);
      final userMissions = await _getUserCurrentMissions(user.id);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('User Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Username: ${userDetails['username']}'),
                Text('Email: ${userDetails['email']}'),
                Text('Type: ${userTypeToString(user.type)}'),
                Text('Status: ${statusToString(user.status)}'),
                const SizedBox(
                    height: 16), // Add space between details and buttons
                const Text('Current Missions:'),
                userMissions.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: userMissions
                            .map((mission) => Text('- ${mission.name}'))
                            .toList(),
                      )
                    : const Text('No missions available.'),
                const SizedBox(
                    height: 16), // Add space between missions and buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: _buildUserActionsForDetails(user),
                ),
              ],
            ),
          );
        },
      );
    } catch (error) {
      print('Failed to load user details: $error');
      // Handle error
    }
  }

  List<Widget> _buildUserActionsForDetails(User user) {
    if (user.status == Status.PENDING) {
      return [
        ElevatedButton(
          onPressed: () {
            _showApprovalDialog(user.id);
          },
          child: const Text('Approve'),
        ),
        ElevatedButton(
          onPressed: () {
            _rejectUser(user.id);
          },
          child: const Text('Reject'),
        ),
        ElevatedButton(
          onPressed: () {
            _deleteUser(user.id);
          },
          child: const Text('Delete'),
        ),
      ];
    } else if (user.status == Status.REJECTED) {
      return [
        ElevatedButton(
          onPressed: () {
            _showApprovalDialog(user.id);
          },
          child: const Text('Approve'),
        ),
      ];
    } else {
      return [
        ElevatedButton(
          onPressed: () {
            _editUser(user);
          },
          child: const Text('Edit'),
        ),
        ElevatedButton(
          onPressed: () {
            _deleteUser(user.id);
          },
          child: const Text('Delete'),
        ),
      ];
    }
  }

  Future<void> _nextPage() async {
    setState(() {
      _pageNumber++;
    });
    await _fetchUsers();
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
    if (user.status == Status.PENDING) {
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
              _showApprovalDialog(user.id);
            } else if (value == 2) {
              _rejectUser(user.id);
            } else if (value == 3) {
              _deleteUser(user.id);
            }
          },
        ),
      ];
    } else if (user.status == Status.REJECTED) {
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
              _showApprovalDialog(user.id);
            }
          },
        ),
      ];
    } else if (user.status == Status.INACTIVE) {
      return [];
    } else {
      return [
        PopupMenuButton<int>(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 1,
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 2,
              child: Text('Delete'),
            ),
          ],
          onSelected: (value) {
            if (value == 1) {
              _editUser(user);
            } else if (value == 2) {
              _deleteUser(user.id);
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
}
