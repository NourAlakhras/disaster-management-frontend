import 'package:flutter/material.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/services/admin_api_service.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/selection_widget.dart';

class EditUsersScreen extends StatefulWidget {
  final List<User>? preselectedUsers;
  final String? missionId; // Add missionId parameter

  EditUsersScreen(
      {this.preselectedUsers, this.missionId}); // Modify constructor

  @override
  _EditUsersScreenState createState() => _EditUsersScreenState();
}

class _EditUsersScreenState extends State<EditUsersScreen> {
  late List<User> _userOptions;
  late List<User> _selectedUsers = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedUsers = widget.preselectedUsers ?? [];
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<User> users = await AdminApiService.getAllUsers(
        pageNumber: 1,
        pageSize: 100,
        statuses: [
          UserStatus.AVAILABLE,
          UserStatus.ASSIGNED,
          UserStatus.ACCEPTED
        ],
      );
      setState(() {
        _userOptions = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to fetch users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Users'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop<List<User>>(context, _selectedUsers);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SelectionWidget<User>(
              items: _userOptions,
              preselectedItems: _selectedUsers,
              onSelectionChanged: (selectedUsers) {
                setState(() {
                  _selectedUsers = selectedUsers;
                  print('EditUsersScreen selectedUsers: $_selectedUsers');
                });
              },
            ),
    );
  }
}
