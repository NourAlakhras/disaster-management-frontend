import 'package:flutter/material.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/screens/admin/edit_missions_screen.dart';
import 'package:flutter_3/screens/admin/mission_devices_base_screen.dart';
import 'package:flutter_3/services/admin_api_service.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';

class UserProfileScreen extends StatefulWidget {
  final User user;
  final MQTTClientWrapper mqttClient;

  const UserProfileScreen(
      {super.key, required this.mqttClient, required this.user});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();

  List<Mission> _selectedMissions = [];

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(144, 41, 48, 56),
      appBar: CustomUpperBar(
        title: 'user Profile',
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
                    label: 'Username',
                    controller: _userNameController,
                    isEditing: _isEditing,
                  ),
                  const SizedBox(height: 8),
                  _buildEditableField(
                    label: 'Email',
                    controller: _userEmailController,
                    isEditing: _isEditing,
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
                            widget.user.status
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
                        children: _buildUserActions(widget.user),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Type: ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          Text(
                            widget.user.type
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
                        children: _buildTypeSwitchActions(widget.user),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  _isEditing
                      ? _buildEditableMissionSelection()
                      : _buildNonEditableMissionSelection(),
                  const SizedBox(height: 20),
                  _buildEditButton(),
                ],
              ),
            ),
    );
  }

  Future<void> _fetchUserDetails() async {
    if (!mounted) return; // Check if the widget is mounted before proceeding
    setState(() {
      _isLoading = true;
    });
    try {
      final userDetails =
          await AdminApiService.getUserDetails(widget.user.user_id);

      if (!mounted) {
        return;
      }
      setState(() {
        // Update user details directly on the widget.user object
        widget.user.username = userDetails.username;
        widget.user.email = userDetails.email;
        widget.user.status = userDetails.status;
        widget.user.type = userDetails.type;
        widget.user.activeMissionCount = userDetails.activeMissionCount;
        widget.user.missions = userDetails.missions;

        _userNameController.text = userDetails.username;
        _userEmailController.text = userDetails.email!;

        _selectedMissions = userDetails.missions!;
        print('user object ${widget.user}');
      });
    } catch (e) {
      print('Error fetching user info: $e');
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
          'Missions:',
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
              trailing: (widget.user.status == UserStatus.ASSIGNED)
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

  Future<void> _showApprovalDialog(String userId) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Approve User'),
          content: const Text('Approve as admin or regular user?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _approveUser(userId, isAdmin: true);
              },
              child: const Text('Admin'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _approveUser(userId, isAdmin: false);
              },
              child: const Text('Regular User'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _approveUser(String userId, {required bool isAdmin}) async {
    try {
      // Call the API to approve the user account
      await AdminApiService.approveUser(userId, isAdmin);
      // After successful approval, refresh the user list
      await _fetchUserDetails();
    } catch (error) {
      print('Failed to approve user: $error');
    }
  }

  Future<void> _rejectUser(String userId) async {
    try {
      await AdminApiService.rejectUser(userId);
      await _fetchUserDetails();
    } catch (error) {
      print('Failed to reject user: $error');
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await AdminApiService.deleteUser(userId);
      await _fetchUserDetails();
    } catch (error) {
      print('Failed to delete user: $error');
    }
  }

  List<Widget> _buildUserActions(User user) {
    switch (user.status) {
      case UserStatus.PENDING:
        return [
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: Text('Approve'),
              ),
              const PopupMenuItem(
                value: 2,
                child: Text('Reject'),
              ),
              const PopupMenuItem(
                value: 3,
                child: Text('Delete'),
              ),
            ],
            onSelected: (value) {
              if (value == 1) {
                _showApprovalDialog(user.user_id);
              } else if (value == 2) {
                _rejectUser(user.user_id);
              } else if (value == 3) {
                _deleteUser(user.user_id);
              }
            },
          ),
        ];
      //   ElevatedButton(
      //     onPressed: () {
      //       _showApprovalDialog(user.user_id);
      //     },
      //     child: const Text('Approve'),
      //   ),
      //   const SizedBox(width: 5),
      //   ElevatedButton(
      //     onPressed: () {
      //       _rejectUser(user.user_id);
      //     },
      //     child: const Text('Reject'),
      //   ),
      //   ElevatedButton(
      //     onPressed: () {
      //       _deleteUser(user.user_id);
      //     },
      //     child: const Text('Delete'),
      //   ),
      // ];
      case UserStatus.REJECTED:
        return [
          ElevatedButton(
            onPressed: () {
              _showApprovalDialog(user.user_id);
            },
            child: const Text('Approve'),
          ),
          const SizedBox(width: 5),
        ];
      default:
        return [
          ElevatedButton(
            onPressed: () {
              _deleteUser(user.user_id);
            },
            child: const Text('Delete'),
          ),
        ];
    }
  }

  Widget _buildEditableMissionSelection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Missions:',
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
    if (widget.user.status == MissionStatus.FINISHED ||
        widget.user.status == MissionStatus.CANCELED) {
      // If user status is FINISHED or CANCELED, return an empty container
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

  void _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Extract user details
      final String userId = widget.user.user_id;
      final String username = _userNameController.text;
      final String email = _userNameController.text;
      final List<String> missionIds =
          _selectedMissions.map((mission) => mission.id).toList();

      print('save missions : $missionIds');

      // Call updateuser API
      await AdminApiService.updateUser(
        user_id: userId,
        username: username,
        email: email,
        missionIds: missionIds,
      );
      await _fetchUserDetails();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('user updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error message if update fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  _buildTypeSwitchActions(User user) {
    switch (user.type) {
      case UserType.ADMIN:
        return [
          ElevatedButton(
            onPressed: () {
              
            },
            child: const Text('Switch to Regular'),
          ),
          const SizedBox(width: 5),
        ];
      default:
        return [
          ElevatedButton(
            onPressed: () {
            },
            child: const Text('Switch to Admin'),
          ),
        ];
    }
  }
}
