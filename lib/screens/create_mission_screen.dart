import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/screens/edit_mission_brokers_screen.dart';
import 'package:flutter_3/screens/edit_mission_devices_screen.dart';
import 'package:flutter_3/screens/edit_mission_users_screen.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/utils/app_colors.dart';
import 'package:flutter_3/widgets/editable_field_widget.dart';

class CreateMissionScreen extends StatefulWidget {
  const CreateMissionScreen({Key? key}) : super(key: key);

  @override
  _CreateMissionScreenState createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  final TextEditingController _missionNameController = TextEditingController();
  List<User> _selectedUsers = [];
  List<Device> _selectedDevices = [];
  Device? _selectedBroker; // Broker can be null initially

  bool _isLoading = false;
  bool _isMissionNameValid = true;
  bool _isBrokerSelected = false;

  @override
  void dispose() {
    _missionNameController.dispose();
    super.dispose();
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
                    builder: (context) => EditMissionUsersScreen(
                        preselectedUsers: _selectedUsers),
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
                    builder: (context) => EditMissionDevicesScreen(
                        brokerId: _selectedBroker!.device_id,
                        preselectedDevices: _selectedDevices),
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
                    builder: (context) => EditMissionBrokerScreen(
                        preselectedBroker: _selectedBroker),
                  ),
                );
                if (selectedBroker != null) {
                  setState(() {
                    if (_selectedBroker != null &&
                        _selectedBroker!.device_id !=
                            selectedBroker.device_id) {
                      print('_selectedBroker $_selectedBroker');
                      print('selectedBroker $selectedBroker');
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
                    _isBrokerSelected = true; // Reset broker validation
                  });
                }
              },
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
            ),
          ],
        ),
        _isBrokerSelected
            ? ListTile(
                title: Text(
                  _selectedBroker!.name,
                  style: const TextStyle(color: secondaryTextColor),
                ),
              )
            : SizedBox()
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
                  EditableFieldWidget(
                    label: 'Mission Name',
                    controller: _missionNameController,
                    isEditing: true,
                    isValid: _isMissionNameValid,
                    errorText: _isMissionNameValid
                        ? null
                        : 'Mission name must be 3-20 characters long',
                    onChanged: (value) {
                      setState(() {
                        _isMissionNameValid = Mission.validateName(value);
                      });
                    },
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
                      } else {
                        if (!_isBrokerSelected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a broker.'),
                              backgroundColor: errorColor,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
    );
  }

  bool _validateForm() {
    // Validate broker selection
    final isBrokerValid = _selectedBroker != null;
    setState(() {
      _isMissionNameValid =
          Mission.validateName(_missionNameController.text.trim());
    });
    setState(() {
      _isBrokerSelected = isBrokerValid;
    });

    return _isMissionNameValid && isBrokerValid;
  }

  void _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    final mission = Mission(
      id: '', // Initially empty or assign a default value
      name: _missionNameController.text.trim(),
      broker: _selectedBroker!,
      users: _selectedUsers,
      devices: _selectedDevices,
    );

    final missionId = await mission.createMission(context:context,
      missionName: mission.name,
      userIds: _selectedUsers.map((user) => user.user_id).toList(),
      brokerId: _selectedBroker!.device_id,
      deviceIds: _selectedDevices.map((device) => device.device_id).toList(),
    );

    setState(() {
      _isLoading = false;
    });

    if (missionId != null) {
      Navigator.pop(
          context, missionId); // Navigate back with the new mission ID
    } else {
      print('Failed to create mission');
    }
  }
}
