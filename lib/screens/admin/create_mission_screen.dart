import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/screens/admin/edit_mission_brokers_screen.dart';
import 'package:flutter_3/screens/admin/edit_mission_devices_screen.dart';
import 'package:flutter_3/screens/admin/edit_mission_users_screen.dart';
import 'package:flutter_3/services/mission_api_service.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/utils/app_colors.dart';

class CreateMissionScreen extends StatefulWidget {
  const CreateMissionScreen({Key? key});

  @override
  _CreateMissionScreenState createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  final TextEditingController _missionNameController = TextEditingController();
  List<User> _selectedUsers = [];
  List<Device> _selectedDevices = [];
  Device? _selectedBroker;

  bool _isLoading = false;
  bool isMissionNameValid = true;

  @override
  void dispose() {
    _missionNameController.dispose();
    super.dispose();
  }

  bool _validateMissionName(String value) {
    return value.isNotEmpty && value.length >= 3 && value.length <= 20;
  }

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
                color: primaryTextColor,
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
                style: const TextStyle(color: secondaryTextColor),
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
                color: primaryTextColor,
              ),
            ),
            IconButton(
              onPressed: () async {
                if (_selectedBroker == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a broker first.'),
                      backgroundColor: errorColor,
                    ),
                  );
                  return;
                }

                List<Device>? selectedDevices = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditDevicesScreen(
                      brokerId: _selectedBroker!.device_id,
                    ),
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
                style: const TextStyle(color: secondaryTextColor),
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
                color: primaryTextColor,
              ),
            ),
            IconButton(
              onPressed: () async {
                Device? selectedBroker = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditBrokersScreen(),
                  ),
                );
                if (selectedBroker != null) {
                  setState(() {
                    if (_selectedBroker != null &&
                        _selectedBroker!.device_id !=
                            selectedBroker.device_id) {
                      _selectedDevices = [];
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Broker changed, device selection cleared.'),
                          backgroundColor: warningColor,
                        ),
                      );
                    }
                    _selectedBroker = selectedBroker;
                  });
                }
              },
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
            ),
          ],
        ),
        _selectedBroker != null
            ? ListTile(
                title: Text(
                  _selectedBroker!.name,
                  style: const TextStyle(color: secondaryTextColor),
                ),
              )
            : Container(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomUpperBar(
        title: 'Create New Mission',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: primaryTextColor,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: primaryTextColor,
            onPressed: () {},
          )
        ],
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
                    isValid: isMissionNameValid,
                    errorText: isMissionNameValid
                        ? null
                        : 'Mission name must be 3-20 characters long',
                  ),
                  const SizedBox(height: 20),
                  _buildEditableUserSelection(),
                  const SizedBox(height: 20),
                  _buildEditableBrokerSelection(),
                  const SizedBox(height: 20),
                  _buildEditableDeviceSelection(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_validateForm()) {
                        _saveChanges();
                      }
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
    required bool isValid,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        TextFormField(
          controller: controller,
          style: const TextStyle(
            color: primaryTextColor,
          ),
          onChanged: (value) {
            setState(() {
              isMissionNameValid = _validateMissionName(value);
            });
          },
          decoration: InputDecoration(
            errorText: errorText,
          ),
        ),
      ],
    );
  }

  bool _validateForm() {
    return isMissionNameValid;
  }

  void _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String missionName = _missionNameController.text;
      final List<String> userIds =
          _selectedUsers.map((user) => user.user_id).toList();

      final String brokerId = _selectedBroker?.device_id ?? '';

      final List<String> deviceIds =
          _selectedDevices.map((device) => device.device_id).toList();
      // Call createMission API
      String? missionId = await MissionApiService.createMission(
        name: missionName,
        deviceIds: deviceIds,
        userIds: userIds,
        brokerId: brokerId,
      );
      if (missionId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mission created successfully'),
            backgroundColor: successColor,
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Mission creation returned null');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create mission: $e'),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
