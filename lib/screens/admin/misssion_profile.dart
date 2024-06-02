import 'package:flutter/material.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/screens/admin/edit_mission_brokers_screen.dart';
import 'package:flutter_3/screens/admin/edit_mission_devices_screen.dart';
import 'package:flutter_3/screens/admin/edit_mission_users_screen.dart';
import 'package:flutter_3/screens/admin/mission_devices_base_screen.dart';
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
  Device? _selectedBroker;

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
                  const SizedBox(height: 8),
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
                        const SizedBox(height: 8),
                      ],
                    ),
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
                        const SizedBox(height: 8),
                      ],
                    ),
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
                  const SizedBox(height: 8),
                  _isEditing
                      ? _buildEditableUserSelection()
                      : _buildNonEditableUserSelection(),
                  const SizedBox(height: 20),
                  _isEditing
                      ? _buildEditableBrokerSelection()
                      : _buildNonEditableBrokerSelection(),
                  const SizedBox(height: 20),
                  _isEditing
                      ? _buildEditableDeviceSelection()
                      : _buildNonEditableDeviceSelection(),
                  const SizedBox(height: 20),
                  _buildEditButton(),
                  _buildMonitorButton(),
                ],
              ),
            ),
    );
  }

  Future<void> fetchMissionDetails() async {
    widget.mission.fetchMissionDetails(() {
      if (mounted) {
        setState(() {
          _missionNameController.text = widget.mission.name;
          _selectedBroker = widget.mission.broker;
          _selectedDevices = widget.mission.devices!
              .where((device) => device.type != DeviceType.BROKER)
              .toList();
          _selectedUsers = widget.mission.users!;
        });
      }
    });
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
        _selectedUsers.isEmpty
            ? const Text(
                'No users assigned',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              )
            : Column(
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
        _selectedDevices.isEmpty
            ? const Text(
                'No devices assigned',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              )
            : Column(
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
                              ).then((_) {
                                setState(() {
                                  // Call setState to refresh the page.
                                });
                              });
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
        _selectedBroker == null
            ? const Text(
                'No broker assigned',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              )
            : ListTile(
                title: Text(
                  _selectedBroker!.name,
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: (widget.mission.status == MissionStatus.ONGOING)
                    ? ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeviceDetailedScreen(
                                device: _selectedBroker!,
                                mqttClient: widget.mqttClient,
                              ),
                            ),
                          ).then((_) {
                            setState(() {
                              // Call setState to refresh the page.
                            });
                          });
                        },
                        child: const Text('Monitor Device'),
                      )
                    : const SizedBox.shrink(),
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
                ).then((_) {
                  setState(() {
                    // Call setState to refresh the page.
                  });
                });
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
                if (_selectedBroker == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a broker first.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                List<Device> selectedDevices = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditDevicesScreen(
                      preselectedDevices: _selectedDevices,
                      missionId: widget.mission.id,
                      brokerId: _selectedBroker!.device_id,
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
                if (widget.mission.status != MissionStatus.CREATED) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'You are not able to change the broker of a started mission.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

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
                          backgroundColor: Colors.orange,
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
                  style: const TextStyle(color: Colors.white70),
                ),
              )
            : Container(),
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
    if (UserCredentials().getUserType() == UserType.ADMIN) {
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
    } else {
      return const SizedBox();
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
    if (UserCredentials().getUserType() == UserType.ADMIN) {
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
    } else {
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
      final String missionName = _missionNameController.text;
      final List<String> userIds =
          _selectedUsers.map((user) => user.user_id).toList();

      final String brokerId = _selectedBroker?.device_id ?? '';

      final List<String> deviceIds =
          _selectedDevices.map((device) => device.device_id).toList();

      await MissionApiService.updateMission(
        name: missionName,
        deviceIds: deviceIds,
        userIds: userIds,
        brokerId: brokerId,
        missionId: widget.mission.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mission created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
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
