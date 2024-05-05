import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/screens/admin/mission_devices_list_screen.dart';
import 'package:flutter_3/services/admin_api_service.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/services/mission_api_service.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/custom_button.dart';
import 'package:multi_dropdown/enum/app_enums.dart';
import 'package:multi_dropdown/models/chip_config.dart';
import 'package:multi_dropdown/models/value_item.dart';
import 'package:multi_dropdown/multiselect_dropdown.dart';

class MissionProfileScreen extends StatefulWidget {
  final Mission mission;
  final MQTTClientWrapper mqttClient;

  MissionProfileScreen({
    Key? key,
    required this.mqttClient,
    required this.mission,
  }) : super(key: key);

  @override
  _MissionProfileScreenState createState() => _MissionProfileScreenState();
}

class _MissionProfileScreenState extends State<MissionProfileScreen> {
  Mission? mission;
  bool _isLoading = false;
  bool _isEditing = false;
  final TextEditingController _missionNameController = TextEditingController();
  List<ValueItem> _userOptions = [];
  List<ValueItem> _deviceOptions = [];
    List<Device> _selectedDevices = [];

  List<User> _selectedUsers = [];
  @override
  void initState() {
    super.initState();
    _missionNameController.text = widget.mission.name;
    fetchMissionDetails();
        _fetchDevices();

    _fetchUsers();
  }

  Future<void> fetchMissionDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final missionDetails =
          await MissionApiService.getMissionDetails(widget.mission.id);
      setState(() {
        mission = missionDetails;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching mission info: $e');
    }
  }
Future<void> _saveChanges() async {
    // Save changes to mission details
    try {
      // Update mission name if edited
      if (_isEditing) {
        await MissionApiService.updateMission(
          missionId: widget.mission.id,
          name: _missionNameController.text,
          deviceIds: _selectedDevices.map((device) => device.id).toList(),
          userIds: _selectedUsers.map((user) => user.id).toList(),
        );
      }
      // Fetch mission details again to update UI
      await fetchMissionDetails();
    } catch (e) {
      print('Error saving changes: $e');
      // Handle error
      // Show snackbar or any other UI indication
    }
    // Exit editing mode
    _toggleEditing();
  }


  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
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
          : mission != null
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _isEditing
                          ? TextField(
                              controller: _missionNameController,
                              style: const TextStyle(
                                  color: Colors.white), // Change text color
                              decoration: const InputDecoration(
                                labelText: 'Mission Name',
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color.fromARGB(255, 255, 255,
                                        254), // Change border color when focused
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  color:
                                      Colors.white, // Change label text color
                                ),
                              ),
                            )
                          : Text(
                              'Mission Name: ${mission!.name}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                      const SizedBox(height: 10),
                      Text(
                        'Start Date: ${mission!.startDate != null ? mission!.startDate!.toString() : 'N/A'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'End Date: ${mission!.endDate != null ? mission!.endDate!.toString() : 'N/A'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Status: ${mission!.status.toString().split('.').last.toLowerCase()}',
                        style: const TextStyle(color: Colors.white70),
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
                          ? MultiSelectDropDown(
                              onOptionSelected:
                                  (List<ValueItem> selectedOptions) {
                                setState(() {
                                  _selectedUsers = selectedOptions
                                      .map((option) => option.value as User)
                                      .toList();
                                });
                              },
                              onOptionRemoved: (int index,
                                  ValueItem<dynamic> removedOption) {
                                setState(() {
                                  _selectedUsers.remove(removedOption.value);
                                });
                              },
                              options: _userOptions,
                              selectionType: SelectionType.multi,
                              chipConfig:
                                  const ChipConfig(wrapType: WrapType.scroll),
                              optionTextStyle: const TextStyle(fontSize: 16),
                              selectedOptionIcon:
                                  const Icon(Icons.check_circle),
                              // Initialize selected options with mission users when in editing mode
                              selectedOptions: _isEditing
                                  ? mission!.users!
                                      .where((user) => _userOptions.any(
                                          (option) => option.value == user))
                                      .map((user) => ValueItem(
                                          label: user.username, value: user))
                                      .toList()
                                  : [],
                            )
                          : Column(
                              children: mission!.users!.map<Widget>((user) {
                                return ListTile(
                                  title: Text(
                                    user.username,
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                  onTap: () {
                                    // Handle user tap
                                  },
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
                          ? MultiSelectDropDown(
                              onOptionSelected:
                                  (List<ValueItem> selectedOptions) {
                                setState(() {
                                  _selectedDevices = selectedOptions
                                      .map((option) => option.value as Device)
                                      .toList();
                                });
                              },
                              options: _deviceOptions,
                              selectionType: SelectionType.multi,
                              chipConfig:
                                  const ChipConfig(wrapType: WrapType.scroll),
                              optionTextStyle: const TextStyle(fontSize: 16),
                              selectedOptionIcon:
                                  const Icon(Icons.check_circle),
                              // Initialize selected options with mission devices when in editing mode
                              selectedOptions: _isEditing
                                  ? mission!.devices!
                                      .map((device) => ValueItem(
                                          label: device.name, value: device))
                                      .toList()
                                  : [],
                            )
                          : Column(
                              children: mission!.devices!.map<Widget>((device) {
                                return ListTile(
                                  title: Text(
                                    device.name,
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                  subtitle: Text(
                                    'Type: ${device.type.toString().split('.').last.toLowerCase()}',
                                    style:
                                        const TextStyle(color: Colors.white38),
                                  ),
                                  trailing: _isEditing
                                      ? ElevatedButton(
                                          onPressed: () {
                                            // Handle monitoring/control for this device
                                          },
                                          child: const Text('Monitor/Control'),
                                        )
                                      : null,
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 20),
                      _isEditing
                          ? CustomButton(
                              text: 'Save Changes',
                              onPressed: _saveChanges,
                            )
                          : CustomButton(
                              text: 'Edit',
                              onPressed: _toggleEditing,
                            ),
                      CustomButton(
                        text: "Go to Mission Monitor/Control",
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MissionDevicesListScreen(
                              mqttClient: widget.mqttClient,
                              mission: widget.mission,
                              devices: mission!.devices!,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const Center(
                  child: Text(
                    'Mission details not available',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
    );
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<User> users = await AdminApiService.getAllUsers(
          pageNumber: 1,
          pageSize: 100,
          statuses: [
            Status.AVAILABLE,
            Status.ASSIGNED,
          ]);
      setState(() {
        _userOptions = users
            .map((user) => ValueItem(label: user.username, value: user))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to fetch users: $e');
    }
  }

  Future<void> _fetchDevices() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<Device> devices = await DeviceApiService.getAllDevices(
        pageNumber: 1,
        pageSize: 100,
        statuses: [DeviceStatus.AVAILABLE],
      );
      print(devices);
      setState(() {
        _deviceOptions = devices
            .map((device) => ValueItem(label: device.name, value: device))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching devices: $e');
      // Handle error gracefully, show a snackbar or a dialog to inform the user
      // Alternatively, you can set _deviceOptions to an empty list here
      throw Exception('Failed to fetch devices: $e');
    }
  }

}
