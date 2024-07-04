import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/screens/admin/mission_devices_base_screen.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/screens/user/device_detailed_screen.dart';
import 'package:flutter_3/utils/app_colors.dart';

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
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
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
      appBar: CustomUpperBar(
        title: 'Device Profile',
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
                    label: 'Device Name',
                    controller: _deviceNameController,
                    isEditing: _isEditing,
                  ),
                  const SizedBox(height: 8),
                  if (_isEditing)
                    Column(
                      children: [
                        _buildEditableField(
                          label: 'New Password',
                          controller: _newPasswordController,
                          isEditing: _isEditing,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  if (widget.device.mac != null)
                    Row(
                      children: [
                        const Text(
                          'MAC Address: ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                        Text(
                          widget.device.mac.toString(),
                          style: const TextStyle(
                            color: secondaryTextColor,
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
                              color: primaryTextColor,
                            ),
                          ),
                          Text(
                            widget.device.status
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
                        children: _buildDeviceActions(widget.device),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Type: ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      Text(
                        widget.device.type
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
                  if (widget.device.broker != null)
                    Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Broker: ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                            Text(
                              widget.device.broker!.name,
                              style: const TextStyle(
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
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
    widget.device.fetchDeviceDetails(() {
      if (mounted) {
        setState(() {
          _deviceNameController.text = widget.device.name;
          _selectedMissions =
              widget.device.mission != null ? [widget.device.mission!] : [];
        });
      }
    });
  }

  Widget _buildNonEditableMissionSelection() {
    if (widget.device.status != DeviceStatus.ASSIGNED) {
      return const SizedBox();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mission:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        _selectedMissions.isEmpty
            ? const Text(
                'No missions assigned',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                ),
              )
            : Column(
                children: _selectedMissions.map((mission) {
                  return ListTile(
                    title: Text(
                      mission.name,
                      style: const TextStyle(color: secondaryTextColor),
                    ),
                    trailing: (mission.status == MissionStatus.ONGOING)
                        ? ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MissionDevicesListScreen(
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
    if (widget.device.status != DeviceStatus.ASSIGNED) {
      return const SizedBox();
    }
    return Column(
      children: [
        const Text(
          'Mission:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        Column(
          children: _selectedMissions.map((mission) {
            return ListTile(
              title: Text(
                mission.name,
                style: const TextStyle(color: secondaryTextColor),
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
      if (widget.device.status == DeviceStatus.INACTIVE) {
        return const SizedBox();
      } else {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: ElevatedButton(
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                _showPasswordDialog();
              }
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
    if (!_isEditing &&
        widget.device.status == DeviceStatus.ASSIGNED &&
        widget.device.mission?.status == MissionStatus.ONGOING) {
      return ElevatedButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeviceDetailedScreen(
                  device: widget.device,
                  mqttClient: widget.mqttClient,
                ),
              )).then((_) {
            setState(() {
              // Call setState to refresh the page.
            });
          });
        },
        child: const Text('Monitor Device'),
      );
    } else {
      return const SizedBox();
    }
  }

  List<Widget> _buildDeviceActions(Device device) {
    if (UserCredentials().getUserType() == UserType.ADMIN) {
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
    } else {
      return [];
    }
  }

  void _deleteDevice(String id) {
    DeviceApiService.deleteDevice(id).then((deletedDevice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device deleted successfully'),
          backgroundColor: successColor,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete device: $error'),
          backgroundColor: errorColor,
        ),
      );
    });
  }

  void _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String deviceId = widget.device.device_id;
      final String? deviceName =
          _deviceNameController.text != widget.device.name
              ? _deviceNameController.text
              : null;
      final String? oldPassword = widget.device.password;
      String? newPassword = _newPasswordController.text.isNotEmpty
          ? _newPasswordController.text
          : null;

      // Check if the new password is the same as the old password
      if (newPassword == null && deviceName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nothing has been updated'),
            backgroundColor: warningColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      if (newPassword == oldPassword) {
        newPassword = null;
      }
      await DeviceApiService.updateDevice(
        deviceId: deviceId,
        name: deviceName,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      await fetchDeviceDetails();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device updated successfully'),
          backgroundColor: successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update device: $e'),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isEditing = false; // Exit editing mode after saving
      });
    }
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter the Device Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _oldPasswordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _checkPassword();
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkPassword() async {
    String oldPassword = _oldPasswordController.text;

    if (oldPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the device password'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await DeviceApiService.verifyPassword(
        deviceId: widget.device.device_id,
        password: oldPassword,
      );
      setState(() {
        _isEditing = true;
        widget.device.password = oldPassword;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password verified successfully'),
          backgroundColor: successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Incorrect password: $e'),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _oldPasswordController.clear();
      });
    }
  }
}
