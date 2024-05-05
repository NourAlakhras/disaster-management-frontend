import 'package:flutter/material.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/screens/admin/mission_devices_list_screen.dart';
import 'package:flutter_3/services/admin_api_service.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/services/mission_api_service.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/custom_button.dart';

class MissionProfileScreen extends StatefulWidget {
  final Mission mission;
  final MQTTClientWrapper mqttClient;

  MissionProfileScreen(
      {Key? key, required this.mqttClient, required this.mission})
      : super(key: key);

  @override
  _MissionProfileScreenState createState() => _MissionProfileScreenState();
}

class _MissionProfileScreenState extends State<MissionProfileScreen> {
  TextEditingController _missionNameController = TextEditingController();
  List<String> _selectedUsers = [];
  List<String> _selectedDevices = [];

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    fetchMissionDetails();
  }

  Future<void> fetchMissionDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final missionDetails =
          await MissionApiService.getMissionDetails(widget.mission.id);
      setState(() {
        _missionNameController.text = missionDetails.name;
        _selectedUsers =
            missionDetails.users!.map((user) => user.username).toList();
        _selectedDevices =
            missionDetails.devices!.map((device) => device.name).toList();
      });
    } catch (e) {
      print('Error fetching mission info: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(144, 41, 48, 56),
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
        backgroundColor: Color.fromARGB(144, 41, 48, 56),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
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
                  const Text(
                    'Users:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  _isEditing
                      ? _buildEditableUserSelection()
                      : Column(
                          children: _selectedUsers.map((user) {
                            return ListTile(
                              title: Text(
                                user,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 20),
                  const Text(
                    'Devices:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  _isEditing
                      ? _buildEditableDeviceSelection()
                      : Column(
                          children: _selectedDevices.map((device) {
                            return ListTile(
                              title: Text(
                                device,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 20),
                  _buildEditButton(),
                ],
              ),
            ),
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        Expanded(
          child: isEditing
              ? TextFormField(
                  controller: controller,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                )
              : Text(
                  controller.text,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEditableUserSelection() {
    // Implement user selection widget for editing
    return Container();
  }

  Widget _buildEditableDeviceSelection() {
    // Implement device selection widget for editing
    return Container();
  }

  Widget _buildEditButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _isEditing = !_isEditing;
          });
        },
        child: Text(_isEditing ? 'Save' : 'Edit'),
      ),
    );
  }
}
