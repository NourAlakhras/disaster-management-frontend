import 'package:flutter/material.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  final MQTTClientWrapper mqttClient;

  const SettingsScreen({Key? key, required this.mqttClient}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<Map<String, dynamic>> _userDataFuture;
  late Future<List<dynamic>> _currentMissionsFuture;
  late String _selectedMissionId = '';
  late Map<String, dynamic> _selectedMissionInfo = {};

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
    _currentMissionsFuture = _getCurrentMissions();
    _loadDefaultMission();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    try {
      return await ApiService.getUserInfo();
    } catch (e) {
      print('Failed to fetch user data: $e');
      throw e;
    }
  }

  Future<List<dynamic>> _getCurrentMissions() async {
    try {
      final List<dynamic> missionData = await ApiService.getCurrentMissions();

      return missionData;
    } catch (e) {
      print('Failed to fetch current missions\' data: $e');
      throw e;
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await widget.mqttClient.logout();
      await ApiService.logout();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    } catch (e) {
      print('Failed to logout: $e');
    }
  }

  Future<void> _updateEmail(String newEmail) async {
    try {
      await ApiService.updateUserInfo('', newEmail);
      setState(() {
        // Update UI with new email
        _userDataFuture = _fetchUserData(); // Refresh user data after update
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Failed to update email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update email: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updatePassword(String newPassword) async {
    try {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Password Change'),
            content:
                const Text('Are you sure you want to change your password?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await ApiService.updatePassword('', newPassword);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Failed to update password: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update password: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadDefaultMission() async {
    // Fetch the list of current missions
    final missions = await ApiService.getCurrentMissions();
    print(missions);
    if (missions.isNotEmpty) {
      setState(() {
        // Set the default selected mission to the first one
        _selectedMissionId = missions[0]['_id'];
        print(_selectedMissionId);
      });
      // Fetch details of the default selected mission
      await _switchMission(_selectedMissionId);
    }
  }

  Future<void> _switchMission(String missionId) async {
    try {
      // Fetch the details of the selected mission
      final missionInfo =
          await ApiService.getMissionInfo(missionId); // Check this method
      setState(() {
        // Update selected mission info
        _selectedMissionInfo = missionInfo;
      });
    } catch (e) {
      print('Failed to switch mission: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to switch mission: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121417),
      appBar: CustomUpperBar(
        title: 'Settings',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: const Color.fromARGB(255, 255, 255, 255),
            onPressed: () {},
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FutureBuilder(
          future: _userDataFuture,
          builder:
              (context, AsyncSnapshot<Map<String, dynamic>> userDataSnapshot) {
            if (userDataSnapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (userDataSnapshot.hasError) {
              return Text('Error: ${userDataSnapshot.error}');
            } else {
              final userData = userDataSnapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Settings',
                    style: TextStyle(
                      color: Colors.white54, // lighter text color
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    title: const Text(
                      'Username',
                      style: TextStyle(
                          color: Colors.white), // Set title color to white
                    ),
                    subtitle: Text(userData['username'],
                        style: const TextStyle(color: Colors.white54)),
                    leading: const Icon(Icons.person, color: Colors.white54),
                  ),
                  ListTile(
                    title: const Text(
                      'Email',
                      style: TextStyle(
                          color: Colors.white), // Set title color to white
                    ),
                    subtitle: Text(userData['email'],
                        style: const TextStyle(color: Colors.white54)),
                    leading: const Icon(Icons.email, color: Colors.white54),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Update Email'),
                            content: TextField(
                              onChanged: (value) {
                                // Implement email validation
                              },
                              decoration: const InputDecoration(
                                hintText: 'Enter new email',
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  String newEmail =
                                      ''; // Get new email from TextField
                                  _updateEmail(newEmail);
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Update'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  ListTile(
                    title: const Text(
                      'Password',
                      style: TextStyle(
                          color: Colors.white), // Set title color to white
                    ),
                    leading: const Icon(Icons.lock, color: Colors.white54),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Change Password'),
                            content: TextField(
                              obscureText: true,
                              onChanged: (value) {
                                // Implement password validation
                              },
                              decoration: const InputDecoration(
                                hintText: 'Enter new password',
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  String newPassword =
                                      ''; // Get new password from TextField
                                  _updatePassword(newPassword);
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Update'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Mission Settings',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    title: const Text(
                      'Current Mission',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                        _selectedMissionInfo.isNotEmpty
                            ? _selectedMissionInfo['name']
                            : 'None',
                        style: const TextStyle(color: Colors.white54)),
                    leading: const Icon(Icons.workspace_premium_outlined,
                        color: Colors.white54),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Select Mission'),
                            content: FutureBuilder(
                              future: _currentMissionsFuture,
                              builder: (context,
                                  AsyncSnapshot<List<dynamic>>
                                      missionsSnapshot) {
                                if (missionsSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else if (missionsSnapshot.hasError) {
                                  return Text(
                                      'Error: ${missionsSnapshot.error}');
                                } else {
                                  final missions = missionsSnapshot.data!;
                                  return SingleChildScrollView(
                                    child: Column(
                                      children: missions.map((mission) {
                                        return ListTile(
                                          title: Text(mission['name']),
                                          onTap: () {
                                            _selectedMissionId = mission['_id'];
                                            _switchMission(_selectedMissionId);
                                            Navigator.of(context).pop();
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    title: const Text(
                      'Log Out',
                      style: TextStyle(
                          color: Colors.white), // Set title color to white
                    ),
                    leading: const Icon(Icons.logout, color: Colors.white54),
                    onTap: () => _logout(context),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
