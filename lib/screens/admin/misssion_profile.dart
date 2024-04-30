import 'package:flutter/material.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/services/admin_api_service.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/services/mission_api_service.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';

class MissionProfileScreen extends StatefulWidget {
  final String missionId;

  MissionProfileScreen({required this.missionId, Key? key}) : super(key: key);

  @override
  _MissionProfileScreenState createState() => _MissionProfileScreenState();
}

class _MissionProfileScreenState extends State<MissionProfileScreen> {
  Map<String, dynamic>? missionDetails;
  List<dynamic>? missionUsers;
  List<dynamic>? missionDevices;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchMissionDetails();
    fetchMissionUsers();
    fetchMissionDevices();
  }

  Future<void> fetchMissionDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final missionDetailsResponse =
          await MissionApiService.getMissionDetails(widget.missionId);
      print(missionDetailsResponse);
      setState(() {
        missionDetails = missionDetailsResponse;
      });
    } catch (e) {
      print('Error fetching mission info: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchMissionUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final missionUsersResponse =
          await AdminApiService.getAllUsers(missionId: widget.missionId);
      setState(() {
        missionUsers = missionUsersResponse ?? [];
      });
    } catch (e) {
      print('Error fetching users info: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchMissionDevices() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final missionDevicesResponse =
          await DeviceApiService.getAllDevices(missionId: widget.missionId);
      setState(() {
        missionDevices = missionDevicesResponse ?? [];
      });
    } catch (e) {
      print('Error fetching devices info: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String getStatusString(int statusValue) {
    return missionStatusValues.entries
        .firstWhere((entry) => entry.value == statusValue)
        .key
        .toString()
        .split('.')[1];
  }

  String getDeviceTypeString(int typeValue) {
    return deviceTypeValues.entries
        .firstWhere((entry) => entry.value == typeValue)
        .key
        .toString()
        .split('.')[1];
  }

  @override
  Widget build(BuildContext context) {
        return Scaffold(
      backgroundColor: const Color(0xff121417),
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
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : missionDetails != null // Check if missionDetails is not null
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mission Name: ${missionDetails!['name']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Start Date: ${(missionDetails!['start_date'])}'),
                      Text('End Date: ${missionDetails!['end_date']}'),
                      Text(
                          'Status: ${getStatusString(missionDetails!['status'])}'),
                      const SizedBox(height: 20),
                      const Text(
                        'Users:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Column(
                        children: (missionDetails!['users'] as List)
                            .map<Widget>((user) {
                          return ListTile(
                            title: Text(user['username']),
                            onTap: () {
                              // Navigate to user details screen
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Devices:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Column(
                        children: (missionDetails!['devices'] as List)
                            .map<Widget>((device) {
                          return ListTile(
                            title: Text(device['name']),
                            subtitle: Text(
                              'Type: ${getDeviceTypeString(device['type'])}',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                // Handle monitoring/control for this device
                              },
                              child: const Text('Monitor/Control'),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to mission monitoring/control page
                        },
                        child: const Text('Go to Mission Monitor/Control'),
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
}
