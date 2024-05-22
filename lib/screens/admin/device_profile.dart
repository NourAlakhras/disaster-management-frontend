import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/screens/admin/edit_missions_screen.dart';
import 'package:flutter_3/screens/admin/mission_devices_list_screen.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/screens/user/device_detailed_screen.dart';

class DeviceProfileScreen extends StatefulWidget {
  final Device device;
  final MQTTClientWrapper mqttClient;

  const DeviceProfileScreen(
      {super.key, required this.mqttClient, required this.device});

  @override
  _DeviceProfileScreenState createState() => _DeviceProfileScreenState();
}

class _DeviceProfileScreenState extends State<DeviceProfileScreen> {
  final TextEditingController _deviceNameController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  List<Mission> _selectedMissions = [];

  @override
  void initState() {
    super.initState();
    fetchDeviceDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(144, 41, 48, 56),
      appBar: CustomUpperBar(
        title: 'Device Profile',
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
                    label: 'Device Name',
                    controller: _deviceNameController,
                    isEditing: _isEditing,
                  ),
                  const SizedBox(height: 20),
                  if (widget.device.mac != null)
                    Row(
                      children: [
                        const Text(
                          'MAC Address: ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                        Text(
                          '${widget.device.mac}',
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
                            widget.device.status
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
                        children: _buildDeviceActions(widget.device),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  _isEditing
                      ? _buildEditableMissionSelection()
                      : _buildNonEditableMissionSelection(),
                  const SizedBox(height: 20),
                  _buildEditButton(),
                  _buildMonitorButton(),
                ],
              ),
            ),
    );
  }

  Future<void> fetchDeviceDetails() async {
    if (!mounted) return; // Check if the widget is mounted before proceeding
    setState(() {
      _isLoading = true;
    });
    try {
      final deviceDetails =
          await DeviceApiService.getDeviceDetails(widget.device.device_id);
      print('deviceDetails $deviceDetails');
      print('device object ${widget.device}');
      if (!mounted) {
        return;
      }
      setState(() {
        // Update device details directly on the widget.device object
        widget.device.name = deviceDetails.name;
        widget.device.status = deviceDetails.status;

        _deviceNameController.text = deviceDetails.name;
        _selectedMissions = [deviceDetails.mission!];
        

        print('device object ${widget.device}');
        print('DeviceProfileScreen _selectedUsers');
        print('mybroker : ${widget.device.mission}');

        for (var i in _selectedMissions) {
          print(i.toString());
        }
      });
    } catch (e) {
      print('Error fetching device info: $e');
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildNonEditableMissionSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mission:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        Column(
          children: _selectedMissions.map((mission) {
            return ListTile(
              title: Text(
                mission.name,
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: (mission.status == MissionStatus.ONGOING)
                  ? ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MissionDevicesListScreen(
                              mission: mission,
                              mqttClient: widget.mqttClient,
                            ),
                          ),
                        );
                      },
                      child: const Text('Monitor Mission'),
                    )
                  : const SizedBox.shrink(),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEditableMissionSelection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mission:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            IconButton(
              onPressed: () async {
                List<Mission> selectedMissions = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditMissionsScreen(
                      preselectedMissions: _selectedMissions,
                      singleSelection: true,
                    ),
                  ),
                );
                setState(() {
                  _selectedMissions = selectedMissions;
                  print('EditMissionsScreen $_selectedMissions');
                });
              },
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
            ),
          ],
        ),
        Column(
          children: _selectedMissions.map((mission) {
            return ListTile(
              title: Text(
                mission.name,
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
    if (widget.device.status == DeviceStatus.INACTIVE ) {
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
    if (!_isEditing && widget.device.status == DeviceStatus.ASSIGNED && widget.device.mission?.status==MissionStatus.ONGOING ) {
      return ElevatedButton(
        onPressed: () {
          // Navigate to the device monitoring screen
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeviceDetailedScreen(
                  device: widget.device,
                  mqttClient: widget.mqttClient,
                ),
              ));
        },
        child: const Text('Monitor Device'),
      );
    } else {
      return const SizedBox();
    }
  }

  List<Widget> _buildDeviceActions(Device device) {
    return (device.status != DeviceStatus.INACTIVE)
        ? [
            ElevatedButton(
              onPressed: () {
                _deleteDevice(device.device_id);
              },
              child: const Text('Delete'),
            ),
            const SizedBox(width: 5)
          ]
        : [];
  }

  void _deleteDevice(String id) {}

  void _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Extract device details
      final String deviceId = widget.device.device_id;
      final String deviceName = _deviceNameController.text;
      final List<String> missionIds =
          _selectedMissions.map((mission) => mission.id).toList();

      print('save missions : $missionIds');
      // Call updateDevice API
      await DeviceApiService.updateDevice(
        deviceId: deviceId,
        name: deviceName,
        missionIds: missionIds,
      );
      await fetchDeviceDetails();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error message if update fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update device: $e'),
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
