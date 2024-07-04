import 'package:flutter/material.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/services/admin_api_service.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_search_bar.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/selection_widget.dart';
import 'package:flutter_3/utils/app_colors.dart';

class EditUsersScreen extends StatefulWidget {
  final List<User>? preselectedUsers;
  final String? missionId;

  EditUsersScreen({this.preselectedUsers, this.missionId});

  @override
  _EditUsersScreenState createState() => _EditUsersScreenState();
}

class _EditUsersScreenState extends State<EditUsersScreen> {
  late List<User> _userOptions = [];
  late List<User> _selectedUsers = [];

  bool _isLoading = false;
  int _pageNumber = 1;
  bool _hasNext = false;
  bool _hasPrev = false;

  @override
  void initState() {
    super.initState();
    _selectedUsers = widget.preselectedUsers ?? [];
    _fetchUsers();
  }

  Future<void> _fetchUsers({int pageNumber = 1}) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userResponse = await AdminApiService.getAllUsers(
        pageNumber: pageNumber,
        pageSize: 5,
        missionId: widget.missionId,
        statuses: [
          UserStatus.AVAILABLE,
          UserStatus.ASSIGNED,
        ],
      );
      if (!mounted) return;

      setState(() {
        _userOptions = userResponse.items;
        _pageNumber = userResponse.page;
        _hasNext = userResponse.hasNext;
        _hasPrev = userResponse.hasPrev;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to fetch users: $e');
    }
  }

  void _nextPage() {
    if (_hasNext) {
      _fetchUsers(pageNumber: _pageNumber + 1);
    }
  }

  void _previousPage() {
    if (_hasPrev) {
      _fetchUsers(pageNumber: _pageNumber - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomUpperBar(
        title: 'Select Users',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: primaryTextColor,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.check),
            color: primaryTextColor,
            onPressed: () {
              Navigator.pop<List<User>>(context, _selectedUsers);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(15, 8, 15.0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: secondaryTextColor),
                ),
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
                    flex: 3,
                    child: Text('Active Mission Count',
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
            // User List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SelectionWidget<User>(
                      items: _userOptions,
                      preselectedItems: _selectedUsers,
                      onSelectionChanged: (selectedUsers) {
                        setState(() {
                          _selectedUsers = selectedUsers;
                          print(
                              'EditUsersScreen selectedUsers: $_selectedUsers');
                        });
                      },
                      itemBuilder: (user, isSelected) =>
                          _buildUserTile(user, isSelected),
                      singleSelection: false,
                    ),
            ),
            // Pagination Controls
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
    );
  }

  Widget _buildUserTile(User user, bool isSelected) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: barColor),
        ),
      ),
      height: 70,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              user.username,
              style: const TextStyle(fontSize: 17, color: secondaryTextColor),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              user.type.toString().split('.').last.toLowerCase(),
              style: const TextStyle(fontSize: 17, color: secondaryTextColor),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              user.activeMissionCount.toString(),
              style: const TextStyle(fontSize: 17, color: secondaryTextColor),
            ),
          ),
          Checkbox(
            value: isSelected,
            onChanged: (bool? value) {},
          ),
        ],
      ),
    );
  }
}
