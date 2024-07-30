import 'package:flutter/material.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/models/user_credentials.dart';
import 'package:flutter_3/screens/settings_screen.dart';
import 'package:flutter_3/services/api_services/admin_api_service.dart';

import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/shared_preferences_utils.dart';
import 'package:flutter_3/widgets/confirmation_dialog.dart';
import 'package:flutter_3/widgets/custom_search_bar.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/filter_drawer.dart';
import 'package:flutter_3/screens/user_profile.dart';
import 'package:flutter_3/utils/app_colors.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  _UsersListScreenState createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final MQTTClientWrapper mqttClientWrapper =
      MQTTClientWrapper(); // Access singleton instance
  List<User> _filteredUsers = [];
  bool _isLoading = false;
  int _pageNumber = 1;
  final int _pageSize = 6;

  final TextEditingController _searchController = TextEditingController();

  List<UserStatus>? _filteredStatuses = UserStatus.values
      .where((status) =>
          status != UserStatus.INACTIVE && status != UserStatus.REJECTED)
      .toList();

  List<UserType>? _filteredTypes = UserType.values;
  String? _name;

  final criteriaList = [
    FilterCriterion(name: 'User Status', options: UserStatus.values),
    FilterCriterion(name: 'User Type', options: UserType.values),
  ];

  bool _hasNext = false;
  bool _hasPrev = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers({
    List<UserStatus>? statuses,
    List<UserType>? types,
    int? pageNumber,
    int? pageSize,
    String? name,
  }) async {
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
      final userResponse = await AdminApiService.getAllUsers(
        context: context,
        pageNumber: pageNumber,
        pageSize: pageSize,
        statuses: statuses,
        types: types,
        username: name,
      );

      if (!mounted) return;

      setState(() {
        _filteredUsers = userResponse.items;
        _hasNext = userResponse.hasNext;
        _hasPrev = userResponse.hasPrev;
      });
    } catch (error) {
      print('Failed to fetch users: $error');
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
        title: "Users' List",
        leading: IconButton(
            icon: const Icon(Icons.settings),
            color: primaryTextColor,
            onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                )),
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
              onChanged: _filterUsers,
              onClear: _clearSearch,
            ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_filteredUsers.isEmpty)
              const Center(
                child: Text(
                  'No users available',
                  style: TextStyle(color: primaryTextColor), // White text color
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
                              flex: 3,
                              child: Text('Type',
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
                      // User Rows
                      ..._filteredUsers.map((user) {
                        return InkWell(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserProfileScreen(user: user),
                              )).then((_) {
                            setState(() {
                              _fetchUsers();
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
                                  child: Text(
                                    user.username,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      color: secondaryTextColor,
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
                                      fontSize: 15,
                                      color: secondaryTextColor,
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
                                      fontSize: 15,
                                      color: secondaryTextColor,
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
                    onPressed: _hasPrev ? _previousPage : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: accentColor,
                      backgroundColor: secondaryTextColor,
                      elevation: 0,
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(Icons.arrow_back),
                  ),
                  ElevatedButton(
                    onPressed: _hasNext ? _nextPage : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: accentColor,
                      backgroundColor: secondaryTextColor,
                      elevation: 0, // No shadow
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
            setState(() {
              _filteredTypes = selectedTypes;
            });
          } else {
            _filteredStatuses = UserStatus.values
                .where((status) => status != UserStatus.INACTIVE)
                .toList();

            _filteredTypes = UserType.values;
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
    setState(() {
      _name = name.isNotEmpty ? name : '';
      _pageNumber = 1;
    });
    _fetchUsers();
  }

  Future<void> _showApprovalDialog(User user) async {
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
                _approveUser(user, isAdmin: true);
              },
              child: const Text('Admin'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _approveUser(user, isAdmin: false);
              },
              child: const Text('Regular User'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _approveUser(User user, {required bool isAdmin}) async {
    try {
      await user.approve(
          context: context,
          isAdmin: isAdmin,
          setStateCallback: () {
            setState(() {}); // Refresh state after approval
          });
    } catch (error) {
      print('Failed to approve user: $error');
    }
  }

  Future<void> _rejectUser(User user) async {
    try {
      await user.reject(
          context: context,
          setStateCallback: () {
            setState(() {}); // Refresh state after rejection
          });
    } catch (error) {
      print('Failed to reject user: $error');
    }
  }

  Future<void> _deleteUser(User user) async {
    try {
      await user.delete(
          context: context,
          setStateCallback: () {
            setState(() {}); // Refresh state after deletion
          });
      print('User deleted successfully');
    } catch (e) {
      print('Failed to delete user: $e');
    }
  }

  Future<void> _handleDeleteUser(User user) async {
    print('UserCredentials().userId ${UserCredentials().userId}');
    // Check if the user is trying to delete their own account
    if (UserCredentials().userId == user.user_id) {
      final bool confirmed = await showConfirmationDialog(
        context: context,
        title: 'Delete Account',
        message:
            'You cannot delete your own account. Are you sure you want to proceed?',
        confirmText: 'Yes, Proceed',
        cancelText: 'Cancel',
      );

      if (confirmed) {
        // Handle deletion logic here
        await _deleteUser(user);
        await _logout();
      }
    } else {
      final bool confirmed = await showConfirmationDialog(
        context: context,
        title: 'Delete Account',
        message: 'Are you sure you want to delete this user?',
        confirmText: 'Delete',
        cancelText: 'Cancel',
      );

      if (confirmed) {
        await _deleteUser(user);
        setState(() {
          // Refresh user list after deletion
          _fetchUsers();
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      mqttClientWrapper.logout(); // Use the singleton instance
      await SharedPreferencesUtils.clearToken();
      UserCredentials().clearUserCredentials();

      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e, stackTrace) {
      print('Error in logout: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to logout.')),
      );
    }
  }

  List<Widget> _buildUserActions(User user) {
    if (UserCredentials().getUserType() != UserType.ADMIN) {
      return [];
    }

    switch (user.status) {
      case UserStatus.PENDING:
        return [
          _buildPopupMenuButton(
            items: [
              _buildPopupMenuItem(1, 'Approve'),
              _buildPopupMenuItem(2, 'Reject'),
            ],
            onSelected: (value) async {
              if (value == 1) {
                _showApprovalDialog(user);
              } else if (value == 2) {
                _rejectUser(user);
              }
            },
          ),
        ];

      case UserStatus.REJECTED:
        return [
          _buildPopupMenuButton(
            items: [
              _buildPopupMenuItem(1, 'Approve'),
            ],
            onSelected: (value) async {
              if (value == 1) {
                _showApprovalDialog(user);
              }
            },
          ),
        ];

      case UserStatus.AVAILABLE:
      case UserStatus.ASSIGNED:
        return [
          _buildPopupMenuButton(
            items: [
              _buildPopupMenuItem(1, 'Delete'),
            ],
            onSelected: (value) async {
              if (value == 1) {
                _handleDeleteUser(user);
              }
            },
          ),
        ];

      case UserStatus.INACTIVE:
        return []; // No actions for inactive users

      default:
        return [];
    }
  }

  PopupMenuButton<int> _buildPopupMenuButton({
    required List<PopupMenuItem<int>> items,
    required void Function(int) onSelected,
  }) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert, color: Colors.grey),
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
