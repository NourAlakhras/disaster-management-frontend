import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/screens/admin/edit_mission_brokers_screen.dart';
import 'package:flutter_3/screens/admin/edit_mission_devices_screen.dart';
import 'package:flutter_3/screens/admin/edit_mission_users_screen.dart';
import 'package:flutter_3/services/admin_api_service.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/services/mission_api_service.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:multi_dropdown/multiselect_dropdown.dart';

class CreateMissionScreen extends StatefulWidget {
  const CreateMissionScreen({Key? key});

  @override
  _CreateMissionScreenState createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  final TextEditingController _missionNameController = TextEditingController();
  List<User> _selectedUsers = [];
  List<Device> _selectedDevices = [];
  List<Device> _selectedBrokers = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Widget _buildEditableUserSelection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Users:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            IconButton(
              onPressed: () async {
                List<User>? selectedUsers = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditUsersScreen(),
                  ),
                );
                if (selectedUsers != null) {
                  setState(() {
                    _selectedUsers = selectedUsers;
                  });
                }
              },
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
            ),
          ],
        ),
        Column(
          children: _selectedUsers.map((user) {
            return ListTile(
              title: Text(
                user.username, // Assuming User class has a 'name' property
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEditableDeviceSelection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Devices:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            IconButton(
              onPressed: () async {
                List<Device>? selectedDevices = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditDevicesScreen(),
                  ),
                );
                if (selectedDevices != null) {
                  setState(() {
                    _selectedDevices = selectedDevices;
                  });
                }
              },
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
            ),
          ],
        ),
        Column(
          children: _selectedDevices.map((device) {
            return ListTile(
              title: Text(
                device.name,
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEditableBrokerSelection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Broker:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            IconButton(
              onPressed: () async {
                List<Device> selectedBrokers = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditBrokersScreen(),
                  ),
                );
                setState(() {
                  _selectedBrokers = selectedBrokers;
                  print('EditDevicesScreen $selectedBrokers');
                });
              },
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
            ),
          ],
        ),
        Column(
          children: _selectedBrokers.map((device) {
            return ListTile(
              title: Text(
                device.name,
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(144, 41, 48, 56),
      appBar: CustomUpperBar(
        title: 'Create New Mission',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color.fromARGB(255, 255, 255, 255),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: const Color.fromARGB(255, 255, 255, 255),
            onPressed: () {},
          )
        ],
        backgroundColor: const Color.fromARGB(144, 41, 48, 56),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEditableField(
                    label: 'Mission Name',
                    controller: _missionNameController,
                  ),
                  const SizedBox(height: 20),
                  _buildEditableUserSelection(),
                  const SizedBox(height: 20),
                  _buildEditableDeviceSelection(),
                  const SizedBox(height: 20),
                  _buildEditableBrokerSelection(),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _saveChanges();
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
  }) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Extract mission details
      final String missionName = _missionNameController.text;
      final List<String> userIds =
          _selectedUsers.map((user) => user.user_id).toList();
      final List<String> deviceIds =
          _selectedDevices.map((device) => device.device_id).toList();

      // Call createMission API
      await MissionApiService.createMission(
        name: missionName,
        deviceIds: deviceIds,
        userIds: userIds,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mission created successfully'),
          backgroundColor: Colors.green,
        ),
      );

// Navigate back to the previous screen
      Navigator.pop(context);
    } catch (e) {
      // Show error message if creation fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create mission: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
