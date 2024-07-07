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
import 'package:flutter/foundation.dart';
import 'package:flutter_3/utils/app_colors.dart';

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
  List<Device> _initialMissionDevices = [];
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
      appBar: CustomUpperBar(
        title: 'Mission Profile',
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
                            color: primaryTextColor,
                          ),
                        ),
                        Text(
                          '${widget.mission.startDate}',
                          style: const TextStyle(
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  widget.mission.endDate != null
                      ? Row(
                          children: [
                            const Text(
                              'End Date:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                            Text(
                              '${widget.mission.endDate}',
                              style: const TextStyle(
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        )
                      : const SizedBox(height: 8),
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
                              color: primaryTextColor,
                            ),
                          ),
                          Text(
                            widget.mission.status
                                .toString()
                                .split('.')
                                .last
                                .toLowerCase(),
                            style: const TextStyle(
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: _buildMissionActions(widget.mission),
                      )
                    ],
                  ),
                  UserCredentials().getUserType() == UserType.ADMIN
                      ? (_isEditing
                          ? _buildEditableUserSelection()
                          : _buildNonEditableUserSelection())
                      : const SizedBox(height: 8),
                  _isEditing
                      ? _buildEditableBrokerSelection()
                      : _buildNonEditableBrokerSelection(),
                  _isEditing
                      ? _buildEditableDeviceSelection()
                      : _buildNonEditableDeviceSelection(),
                  const SizedBox(height: 8),
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
          _selectedUsers = widget.mission.users!.toList();
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
            color: primaryTextColor,
          ),
        ),
        _selectedUsers.isEmpty
            ? const Text(
                'No users assigned',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                ),
              )
            : Column(
                children: _selectedUsers.map((user) {
                  return ListTile(
                    title: Text(
                      user.username,
                      style: const TextStyle(color: secondaryTextColor),
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
            color: primaryTextColor,
          ),
        ),
        _selectedDevices.isEmpty
            ? const Text(
                'No devices assigned',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                ),
              )
            : Column(
                children: _selectedDevices.map((device) {
                  return ListTile(
                    title: Text(
                      device.name,
                      style: const TextStyle(color: secondaryTextColor),
                    ),
                    subtitle: Text(
                      device.type.toString().split('.').last.toLowerCase(),
                      style: const TextStyle(color: secondaryTextColor),
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
                                    broker: widget.mission.broker,
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
            color: primaryTextColor,
          ),
        ),
        _selectedBroker == null
            ? const Text(
                'No broker assigned',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                ),
              )
            : ListTile(
                title: Text(
                  _selectedBroker!.name,
                  style: const TextStyle(color: secondaryTextColor),
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
                                broker: widget.mission.broker,
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
                color: primaryTextColor,
              ),
            ),
            IconButton(
              onPressed: () async {
                List<User> selectedUsers = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditUsersScreen(
                      missionId: widget.mission.id,
                      preselectedUsers: _selectedUsers,
                    ),
                  ),
                );
                setState(() {
                  _selectedUsers = selectedUsers;
                  print('MissionProfileScreen $_selectedUsers');
                  print('MissionProfileScreen initial ${widget.mission.users}');
                });
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
                if (widget.mission.status != MissionStatus.CREATED) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'You are not able to change the broker of a started mission.'),
                      backgroundColor: errorColor,
                    ),
                  );
                  return;
                }

                Device? selectedBroker = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditBrokersScreen(
                      missionId: widget.mission.id,
                      preselectedBroker: widget.mission.broker,
                    ),
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
            color: primaryTextColor,
          ),
        ),
        Expanded(
          child: isEditing
              ? TextFormField(
                  controller: controller,
                  style: const TextStyle(
                    color: secondaryTextColor,
                  ),
                )
              : Text(
                  controller.text,
                  style: const TextStyle(
                    color: secondaryTextColor,
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

//   void _saveChanges() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final String missionNewName = _missionNameController.text;
//       final List<String> missionNewUserIds =
//           _selectedUsers.map((user) => user.user_id).toList();

//       final String missionNewBrokerId = _selectedBroker?.device_id ?? '';

//       final List<String> missionNewDeviceIds =
//           _selectedDevices.map((device) => device.device_id).toList();
// // Build the update data
//       final Map<String, dynamic> updateData = {};

// if (missionNewName != widget.mission.name) {
//         updateData['missionName'] = missionNewName;
//       }

//       await MissionApiService.updateMission(
//         missionId: widget.mission.id,
//         name: updateData['missionName'],
//         deviceIds: deviceIds,
//         userIds: userIds,
//         brokerId: brokerId,
//         missionId: widget.mission.id,
//       );

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Mission created successfully'),
//           backgroundColor: successColor,
//         ),
//       );

//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to create mission: $e'),
//           backgroundColor: errorColor,
//         ),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
  void _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Extract initial mission details
      final String initialMissionName = widget.mission.name;
      final List<String> initialUserIds =
          widget.mission.users!.map((user) => user.user_id).toList();
      final String? initialBrokerId = widget.mission.broker?.device_id;
      final List<String> initialDeviceIds = widget.mission.devices!
          .where((device) => device.type != DeviceType.BROKER)
          .map((device) => device.device_id)
          .toList();

      print('initialUserIds $initialUserIds');
      print('initialDeviceIds $initialDeviceIds');

      // Extract current mission details
      final String currentMissionName = _missionNameController.text;
      final List<String> currentUserIds =
          _selectedUsers.map((user) => user.user_id).toList();
      final String? currentBrokerId = _selectedBroker?.device_id;
      final List<String> currentDeviceIds =
          _selectedDevices.map((device) => device.device_id).toList();

      print('currentUserIds $currentUserIds');
      print('currentDeviceIds $currentDeviceIds');

      // Build the update data
      final Map<String, dynamic> updateData = {};

      if (currentMissionName != initialMissionName) {
        updateData['name'] = currentMissionName;
      }
      if (currentBrokerId != initialBrokerId) {
        updateData['brokerId'] = currentBrokerId;
      }
      if (!listEquals(currentUserIds, initialUserIds)) {
        updateData['userIds'] = currentUserIds;
      }
      if (!listEquals(currentDeviceIds, initialDeviceIds)) {
        updateData['deviceIds'] = currentDeviceIds;
      }

      print('updateData $updateData');

      if (updateData.isNotEmpty) {
        // Call update mission API only if there are changes
        await MissionApiService.updateMission(
          name: updateData['name'],
          deviceIds: updateData['deviceIds'],
          userIds: updateData['userIds'],
          brokerId: updateData['brokerId'],
          missionId: widget.mission.id,
        );

        // Fetch updated mission details to reflect changes
        await fetchMissionDetails();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mission updated successfully'),
            backgroundColor: successColor,
          ),
        );
      } else {
        // Show a message indicating no changes
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No changes to update'),
            backgroundColor: warningColor,
          ),
        );
      }
    } catch (e) {
      // Show error message if update fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update mission: $e'),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isEditing = false;
      });
    }
  }
}
