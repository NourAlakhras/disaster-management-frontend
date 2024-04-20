import 'package:flutter/material.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/services/admin_api_service.dart';
import 'package:flutter_3/services/user_api_service.dart';
import 'package:flutter_3/widgets/user_tile.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/utils/helpers.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/utils/exceptions.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({Key? key}) : super(key: key);

  @override
  _UsersListScreenState createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  bool _isLoading = false;
  int _pageNumber = 1;
  final int _pageSize = 7;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final allUsersResponse = await AdminApiService.getAllUsers(
        pageNumber: _pageNumber,
        pageSize: _pageSize,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: const Color.fromARGB(255, 255, 255, 255),
            onPressed: () {},
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _filteredUsers.isEmpty
              ? Center(
                  child: Text(
                    'No users available',
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
                    onChanged: _filterUsers,
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      hintText: 'Search users by username',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildUserStatisticsCard(
                          title: 'All Users', count: _allUsers.length),
                      _buildUserStatisticsCard(
                        title: 'Pending Users',
                        count: _getUsersCountByStatus(Status.PENDING),
                      ),
                      _buildUserStatisticsCard(
                          title: 'Available Users',
                          count: _getUsersCountByStatus(Status.AVAILABLE)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Labels Row
                        Container(
                          decoration: const BoxDecoration(
                            border:
                                Border(bottom: BorderSide(color: Colors.grey)),
                          ),
                          height:
                              60, // Set the minimum height for the labels row

                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(8.0, 0, 0.0, 0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text('Username',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white70)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('Type',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors
                                              .white70)), // Light text color),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('Status',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors
                                              .white70)), // Light text color),
                                ),
                                Expanded(
                                  child:
                                      SizedBox(), // Placeholder for actions column
                                ),
                              ],
                            ),
                          ),
                        ),
                        // User Rows
                        ..._filteredUsers.map((user) {
                          return Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: Colors.grey)),
                            ),
                            height:
                                55, // Set the minimum height for the labels row

                            child: InkWell(
                              onTap: () => _showUserDetailsDialog(user),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    8.0, 8.0, 0.0, 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex:
                                          3, // Adjust flex values for responsive distribution
                                      child: Text(user.username,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors
                                                  .white70)), // Light text color
                                    ),
                                    Expanded(
                                      flex:
                                          2, // Adjust flex values for responsive distribution
                                      child: Text(statusToString(user.status),
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors
                                                  .white70)), // Light text color
                                    ),
                                    Expanded(
                                      flex:
                                          2, // Adjust flex values for responsive distribution
                                      child: Text(userTypeToString(user.type),
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
                                        children: _buildUserActions(user),
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
                        onPressed:
                            _allUsers.length >= _pageSize ? _nextPage : null,
                        child: const Text('>'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildUserStatisticsCard({required String title, required int count}) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive font size
          final fontSize =
              constraints.maxWidth * 0.12; // Adjust multiplier as needed

          // Set a minimum height for the card
          final minHeight = 100.0;

          return Card(
            child: SizedBox(
              height: minHeight,
              child: ListTile(
                title: Text(
                  title,
                  style: TextStyle(fontSize: fontSize),
                ),
                subtitle: Text(
                  'Count: $count',
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
            ),
          );
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

  int _getUsersCountByStatus(Status status) {
    return _allUsers.where((user) => user.status == status).length;
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
          icon: const Icon(
            Icons.more_vert,
          ),
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
