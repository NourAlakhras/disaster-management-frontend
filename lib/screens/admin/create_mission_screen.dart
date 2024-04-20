import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/services/admin_api_service.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/services/mission_api_service.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:multi_dropdown/multiselect_dropdown.dart';

class CreateMissionScreen extends StatefulWidget {
  @override
  _CreateMissionScreenState createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _deviceIdsController = TextEditingController();
  bool _isLoading = false;
  List<Device> _selectedDevices = [];

  List<User> _selectedUsers = [];
  final MultiSelectController _controller = MultiSelectController();
  List<ValueItem> _userOptions = [];
  List<ValueItem> _deviceOptions = [];

  @override
  void initState() {
    super.initState();
    _fetchDevices();

    _fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Mission'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Mission Name'),
            ),
            SizedBox(height: 20),
            Text('Select Devices:'),
            SizedBox(height: 8),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : MultiSelectDropDown(
                    onOptionSelected: (List<ValueItem> selectedOptions) {
                      setState(() {
                        _selectedDevices = selectedOptions
                            .map((option) => option.value as Device)
                            .toList();
                      });
                    },
                    options: _deviceOptions,
                    selectionType: SelectionType.multi,
                    chipConfig: const ChipConfig(wrapType: WrapType.scroll),
                    optionTextStyle: const TextStyle(fontSize: 16),
                    selectedOptionIcon: const Icon(Icons.check_circle),
                  ),
            SizedBox(height: 20),
            Text('Select Users:'),
            SizedBox(height: 8),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : MultiSelectDropDown(
                    onOptionSelected: (List<ValueItem> selectedOptions) {
                      setState(() {
                        _selectedUsers = selectedOptions
                            .map((option) => option.value as User)
                            .toList();
                      });
                    },
                    options: _userOptions,
                    selectionType: SelectionType.multi,
                    chipConfig: const ChipConfig(wrapType: WrapType.scroll),
                    optionTextStyle: const TextStyle(fontSize: 16),
                    selectedOptionIcon: const Icon(Icons.check_circle),
                  ),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _isLoading ? null : _createMission,
                    child: Text('Create'),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchDevices() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<Device> devices = await DeviceApiService.getAllDevices(
        pageNumber: 1,
        pageSize: 100,
      );
      print(devices);
      setState(() {
        _deviceOptions = devices
            .map((device) => ValueItem(label: device.name, value: device))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching devices: $e');
      // Handle error gracefully, show a snackbar or a dialog to inform the user
      // Alternatively, you can set _deviceOptions to an empty list here
      throw Exception('Failed to fetch devices: $e');
    }
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<User> users = await AdminApiService.getAllUsers(
        pageNumber: 1,
        pageSize: 100,
      );
      setState(() {
        _userOptions = users
            .map((user) => ValueItem(label: user.username, value: user))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to fetch users: $e');
    }
  }

Future<void> _createMission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the names of selected devices and users
      List<String> deviceIds =
          _selectedDevices.map((device) => device.id).toList();
      List<String> userIds = _selectedUsers.map((user) => user.id).toList();

      // Create the mission
      String missionId = await MissionApiService.createMission(
        name: _nameController.text,
        deviceIds: deviceIds,
        userIds: userIds,
      );

      setState(() {
        _isLoading = false;
      });

      // Show a success message or navigate to a different screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mission created successfully with ID: $missionId'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Handle error
      print('Error creating mission: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create mission: $e'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _deviceIdsController.dispose();
    super.dispose();
  }
}
