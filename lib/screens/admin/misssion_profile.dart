import 'package:flutter/material.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/screens/admin/edit_mission_brokers_screen.dart';
import 'package:flutter_3/screens/admin/edit_mission_devices_screen.dart';
import 'package:flutter_3/screens/admin/edit_mission_users_screen.dart';
import 'package:flutter_3/screens/admin/mission_devices_list_screen.dart';
import 'package:flutter_3/services/mission_api_service.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/screens/user/device_detailed_screen.dart';

class MissionProfileScreen extends StatefulWidget {
  final Mission mission;
  final MQTTClientWrapper mqttClient;

  const MissionProfileScreen(
      {super.key, required this.mqttClient, required this.mission});

  @override
  _MissionProfileScreenState createState() => _MissionProfileScreenState();
}

class _MissionProfileScreenState extends State<MissionProfileScreen> {
  final TextEditingController _missionNameController = TextEditingController();
  List<User> _selectedUsers = [];
  List<Device> _selectedDevices = [];
  List<Device> _selectedBrokers = [];

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    fetchMissionDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(144, 41, 48, 56),
      appBar: CustomUpperBar(
        title: 'Mission Profile',
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
                    isEditing: _isEditing,
                  ),
                  const SizedBox(height: 20),
                  if (widget.mission.startDate != null)
                    Row(
                      children: [
                        const Text(
                          'Start Date: ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                        Text(
                          '${widget.mission.startDate}',
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  if (widget.mission.endDate != null)
                    Row(
                      children: [
                        const Text(
                          'End Date:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                        Text(
                          '${widget.mission.endDate}',
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Status: ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          Text(
                            widget.mission.status
                                .toString()
                                .split('.')
                                .last
                                .toLowerCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: _buildMissionActions(widget.mission),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  _isEditing
                      ? _buildEditableUserSelection()
                      : _buildNonEditableUserSelection(),
                  const SizedBox(height: 20),
                  _isEditing
                      ? _buildEditableDeviceSelection()
                      : _buildNonEditableDeviceSelection(),
                  const SizedBox(height: 20),
                  _isEditing
                      ? _buildEditableBrokerSelection()
                      : _buildNonEditableBrokerSelection(),
                  const SizedBox(height: 20),
                  _buildEditButton(),
                  _buildMonitorButton(),
                ],
              ),
            ),
    );
  }

  Future<void> fetchMissionDetails() async {
    if (!mounted) return; // Check if the widget is mounted before proceeding
    setState(() {
      _isLoading = true;
    });
    try {
      final missionDetails =
          await MissionApiService.getMissionDetails(widget.mission.id);
      print('missionDetails $missionDetails');
      print('mission object ${widget.mission}');
      if (!mounted) {
        return;
      }
      setState(() {
        // Update mission details directly on the widget.mission object
        widget.mission.name = missionDetails.name;
        widget.mission.startDate = missionDetails.startDate;
        widget.mission.endDate = missionDetails.endDate;
        widget.mission.status = missionDetails.status;
        widget.mission.devices = missionDetails.devices;
        widget.mission.users = missionDetails.users;
        widget.mission.broker = missionDetails.broker;

        _missionNameController.text = missionDetails.name;
        _selectedUsers = missionDetails.users ?? [];
        _selectedDevices = missionDetails.devices!
            .where((device) => device.type != DeviceType.BROKER)
            .toList();
        _selectedBrokers = missionDetails.devices!
            .where((device) => device.type == DeviceType.BROKER)
            .toList();

        print('mission object ${widget.mission}');
        print('MissionProfileScreen _selectedUsers');
        print('mybroker : ${widget.mission.broker}');

        for (var i in _selectedUsers) {
          print(i.toString());
        }
      });
    } catch (e) {
      print('Error fetching mission info: $e');
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildNonEditableUserSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Users:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        Column(
          children: _selectedUsers.map((user) {
            return ListTile(
              title: Text(
                user.username,
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNonEditableDeviceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Devices:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        Column(
          children: _selectedDevices.map((device) {
            return ListTile(
              title: Text(
                device.name,
                style: const TextStyle(color: Colors.white70),
              ),
              subtitle: Text(
                device.type.toString().split('.').last.toLowerCase(),
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: (widget.mission.status == MissionStatus.ONGOING)
                  ? ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeviceDetailedScreen(
                              device: device,
                              mqttClient: widget.mqttClient,
                            ),
                          ),
                        );
                      },
                      child: const Text('Monitor Device'),
                    )
                  : const SizedBox.shrink(),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNonEditableBrokerSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Broker:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        Column(
          children: _selectedBrokers.map((device) {
            return ListTile(
              title: Text(
                device.name,
                style: const TextStyle(color: Colors.white70),
              ),
              subtitle: Text(
                device.type.toString().split('.').last.toLowerCase(),
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: (widget.mission.status == MissionStatus.ONGOING)
                  ? ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeviceDetailedScreen(
                              device: device,
                              mqttClient: widget.mqttClient,
                            ),
                          ),
                        );
                      },
                      child: const Text('Monitor Device'),
                    )
                  : const SizedBox.shrink(),
            );
          }).toList(),
        ),
      ],
    );
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
                    builder: (context) => EditUsersScreen(
                      missionId: widget.mission.id,
                      preselectedUsers: _selectedUsers,
                    ),
                  ),
                );
                if (selectedUsers != null) {
                  setState(() {
                    _selectedUsers = selectedUsers;
                    print('MissionProfileScreen _selectedUsers');
                    if (_selectedUsers!.isNotEmpty) {
                      for (var item in _selectedUsers) {
                        print(item.toString());
                      }
                    } else {
                      print('MissionProfileScreen no _selectedUsers');
                    }
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
                List<Device> selectedDevices = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditDevicesScreen(
                      preselectedDevices: _selectedDevices,
                      missionId: widget.mission.id,
                    ),
                  ),
                );
                setState(() {
                  _selectedDevices = selectedDevices;
                  print('EditDevicesScreen $_selectedDevices');
                });
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
                    builder: (context) => EditBrokersScreen(
                      preselectedBrokers: _selectedBrokers,
                      missionId: widget.mission.id,
                    ),
                  ),
                );
                setState(() {
                  _selectedBrokers = selectedBrokers;
                  print('EditDevicesScreen $_selectedBrokers');
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

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
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
          child: isEditing
              ? TextFormField(
                  controller: controller,
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                )
              : Text(
                  controller.text,
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    if (widget.mission.status == MissionStatus.FINISHED ||
        widget.mission.status == MissionStatus.CANCELED) {
      // If mission status is FINISHED or CANCELED, return an empty container
      return const SizedBox();
    } else {
      // Otherwise, return the edit button
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: ElevatedButton(
          onPressed: () {
            if (_isEditing) {
              _saveChanges();
            }
            setState(() {
              _isEditing = !_isEditing;
            });
          },
          child: Text(_isEditing ? 'Save' : 'Edit'),
        ),
      );
    }
  }

  Widget _buildMonitorButton() {
    if (!_isEditing && widget.mission.status == MissionStatus.ONGOING) {
      return ElevatedButton(
        onPressed: () {
          // Navigate to the mission monitoring screen
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MissionDevicesListScreen(
                  mission: widget.mission,
                  mqttClient: widget.mqttClient,
                ),
              ));
        },
        child: const Text('Monitor Mission'),
      );
    } else {
      return const SizedBox();
    }
  }

  List<Widget> _buildMissionActions(Mission mission) {
    switch (mission.status) {
      case MissionStatus.CREATED:
        return [
          ElevatedButton(
            onPressed: () {
              _startMission(mission.id);
            },
            child: const Text('Start'),
          ),
          const SizedBox(width: 5),
          ElevatedButton(
            onPressed: () {
              _cancelMission(mission.id);
            },
            child: const Text('Cancel'),
          ),
        ];
      case MissionStatus.ONGOING:
        return [
          ElevatedButton(
            onPressed: () {
              _pauseMission(mission.id);
            },
            child: const Text('Pause'),
          ),
          const SizedBox(width: 5),
          ElevatedButton(
            onPressed: () {
              _endMission(mission.id);
            },
            child: const Text('End'),
          ),
        ];
      case MissionStatus.PAUSED:
        return [
          ElevatedButton(
            onPressed: () {
              _resumeMission(mission.id);
            },
            child: const Text('Resume'),
          ),
          const SizedBox(width: 5),
          ElevatedButton(
            onPressed: () {
              _endMission(mission.id);
            },
            child: const Text('End'),
          ),
        ];
      default:
        return [];
    }
  }

  Future<void> _startMission(String missionId) async {
    try {
      print('missionId $missionId');
      String command = "start";
      await MissionApiService.updateMissionStatus(missionId, command);
      await fetchMissionDetails();
    } catch (error) {
      print('Failed to start mission: $error');
    }
  }

  void _pauseMission(String missionId) async {
    try {
      print('missionId $missionId');
      String command = "pause";
      await MissionApiService.updateMissionStatus(missionId, command);
      await fetchMissionDetails();
    } catch (error) {
      print('Failed to pause mission: $error');
    }
  }

  void _endMission(String missionId) async {
    try {
      print('missionId $missionId');
      String command = "end";
      await MissionApiService.updateMissionStatus(missionId, command);
      await fetchMissionDetails();
    } catch (error) {
      print('Failed to end mission: $error');
    }
  }

  void _cancelMission(String missionId) async {
    try {
      print('missionId $missionId');
      String command = "cancel";
      await MissionApiService.updateMissionStatus(missionId, command);
      await fetchMissionDetails();
    } catch (error) {
      print('Failed to cancel mission: $error');
    }
  }

  void _resumeMission(String missionId) async {
    try {
      print('missionId $missionId');
      String command = "continue";
      await MissionApiService.updateMissionStatus(missionId, command);
      await fetchMissionDetails();
    } catch (error) {
      print('Failed to continue mission: $error');
    }
  }

  void _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Extract mission details
      final String missionId = widget.mission.id;
      final String missionName = _missionNameController.text;
      final List<String> userIds =
          _selectedUsers.map((user) => user.id).toList();

      // Combine selected devices and brokers
      List<Device> allSelectedDevices = List.from(_selectedDevices);
      allSelectedDevices.addAll(_selectedBrokers);
      final List<String> deviceIds =
          allSelectedDevices.map((device) => device.id).toList();

      print('save devices : $deviceIds');
      // Call updateMission API
      await MissionApiService.updateMission(
        missionId: missionId,
        name: missionName,
        deviceIds: deviceIds,
        userIds: userIds,
      );
      await fetchMissionDetails();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mission updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error message if update fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update mission: $e'),
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
