import 'package:flutter/material.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/models/user_credentials.dart';
import 'package:flutter_3/screens/edit_mission_brokers_screen.dart';
import 'package:flutter_3/screens/edit_mission_devices_screen.dart';
import 'package:flutter_3/screens/edit_mission_users_screen.dart';
import 'package:flutter_3/screens/mission_devices_base_screen.dart';
import 'package:flutter_3/services/mission_api_service.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/screens/device_detailed_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_3/utils/app_colors.dart';
import 'package:flutter_3/widgets/editable_field_widget.dart';

class MissionProfileScreen extends StatefulWidget {
  final Mission mission;

  const MissionProfileScreen({super.key, required this.mission});

  @override
  _MissionProfileScreenState createState() => _MissionProfileScreenState();
}

class _MissionProfileScreenState extends State<MissionProfileScreen> {
  final mqttClient = MQTTClientWrapper();

  final TextEditingController _missionNameController = TextEditingController();
  List<User> _selectedUsers = [];
  List<Device> _selectedDevices = [];
  bool _isMissionNameValid = true;
  bool _isBrokerSelected = true;

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
                  EditableFieldWidget(
                    label: 'Mission Name',
                    controller: _missionNameController,
                    isEditing: _isEditing,
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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.mission.fetchMissionDetails(
          setStateCallback: () {
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
          },
          context: context);
    } catch (e) {
      if (mounted) {
        print('Failed to fetch mission details: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                    trailing: (widget.mission.status == MissionStatus.ONGOING &&
                            _shouldBuildMonitorButton(device))
                        ? ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DeviceDetailedScreen(
                                    device: device,
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

  bool _shouldBuildMonitorButton(Device device) {
    final deviceType = device.type.toString().split('.').last.toLowerCase();
    return deviceType != 'broker' &&
        deviceType != 'charging machine' &&
        deviceType != 'not charging machine';
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
                    builder: (context) => EditMissionUsersScreen(
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
                    SnackBar(
                      content: Text('Please select a broker first.'),
                      backgroundColor: errorColor,
                    ),
                  );
                  return;
                }
                List<Device> selectedDevices = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditMissionDevicesScreen(
                      preselectedDevices: _selectedDevices,
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
                    SnackBar(
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
                    builder: (context) => EditMissionBrokerScreen(
                      missionId: widget.mission.id,
                      preselectedBroker: _selectedBroker,
                    ),
                  ),
                );
                print(' profile selectedBroker $selectedBroker');
                setState(() {
                  if (selectedBroker != null) {
                    if (_selectedBroker == null) {
                      _selectedDevices = [];
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Broker selected, devices selection is ready for new selection.'),
                          backgroundColor: successColor,
                        ),
                      );
                    } else if (_selectedBroker!.device_id !=
                        selectedBroker.device_id) {
                      _selectedDevices = [];
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Broker changed, devices selection cleared.'),
                          backgroundColor: warningColor,
                        ),
                      );
                    }
                    _isBrokerSelected = true;
                  } else {
                    _selectedDevices = [];
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'No broker selected, devices selection cleared.'),
                        backgroundColor: errorColor,
                      ),
                    );
                  }
                  _selectedBroker = selectedBroker;
                  print(' profile _selectedBroker $_selectedBroker');
                });
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

  bool _validateForm() {
    final missionName = _missionNameController.text.trim();

    // Validate mission name
    final isNameValid = missionName.isNotEmpty &&
        missionName.length >= 3 &&
        missionName.length <= 20;

    // Validate broker selection
    final isBrokerValid = _selectedBroker != null;

    setState(() {
      _isMissionNameValid = isNameValid;
      _isBrokerSelected = isBrokerValid;
    });

    return isNameValid && isBrokerValid;
  }

  Widget _buildEditButton() {
    if (UserCredentials().getUserType() == UserType.ADMIN) {
      if (widget.mission.status == MissionStatus.FINISHED ||
          widget.mission.status == MissionStatus.CANCELLED) {
        // If mission status is FINISHED or CANCELED, return an empty container
        return const SizedBox();
      } else {
        // Otherwise, return the edit button
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: ElevatedButton(
            onPressed: () {
              if (_isEditing) {
                if (_validateForm()) {
                  _saveChanges();
                  setState(() {
                    _isEditing = false;
                  });
                } else {
                  if (!_isBrokerSelected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please select a broker.'),
                        backgroundColor: errorColor,
                      ),
                    );
                  }
                  if (!_isMissionNameValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Mission name must be 3-20 characters long'),
                        backgroundColor: errorColor,
                      ),
                    );
                  }
                }
              }
              setState(() {
                _isEditing = true;
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
                builder: (context) => MissionDevicesBaseScreen(
                  mission: widget.mission,
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
      final actions = <Widget>[];
      switch (mission.status) {
        case MissionStatus.CREATED:
          actions.addAll([
            _buildActionButton('Start', mission.start),
            _buildActionButton('Cancel', mission.cancel),
          ]);
          break;
        case MissionStatus.ONGOING:
          actions.addAll([
            _buildActionButton('Pause', mission.pause),
            _buildActionButton('End', mission.end),
          ]);
          break;
        case MissionStatus.PAUSED:
          actions.addAll([
            _buildActionButton('Resume', mission.resume),
            _buildActionButton('End', mission.end),
          ]);
          break;
        default:
          break;
      }
      return actions;
    }
    return [];
  }

  Widget _buildActionButton(
    String label,
    Future<void> Function(
            {required BuildContext context,
            required void Function() updateState})
        action,
  ) {
    return ElevatedButton(
      onPressed: () async {
        try {
          await action(
              context: context,
              updateState: () {
                setState(() {});
              });
        } catch (e) {
          print('Failed to update mission status: $e');
        } finally {
          setState(() {});
        }
      },
      child: Text(label),
    );
  }

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
          context: context,
          name: updateData['name'],
          deviceIds: updateData['deviceIds'],
          userIds: updateData['userIds'],
          brokerId: updateData['brokerId'],
          missionId: widget.mission.id,
        );

        // Fetch updated mission details to reflect changes
        await fetchMissionDetails();
      } else {
        // Show a message indicating no changes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No changes to update'),
            backgroundColor: warningColor,
          ),
        );
      }
    } on ArgumentError catch (e) {
      print('Failed to update mission: ${e.message}');
    } catch (e) {
      print('Failed to update mission: ${e}');
    } finally {
      setState(() {
        _isLoading = false;
        _isEditing = false;
      });
    }
  }

  @override
  void dispose() {
    // Dispose your controllers or any listeners here
    _missionNameController.dispose();
    // Ensure you cancel any ongoing operations or listeners
    super.dispose();
  }
}
