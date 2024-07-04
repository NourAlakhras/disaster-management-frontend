import 'package:flutter/material.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/screens/admin/mission_devices_base_screen.dart';
import 'package:flutter_3/services/admin_api_service.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/utils/app_colors.dart';

class UserProfileScreen extends StatefulWidget {
  final User user;
  final MQTTClientWrapper mqttClient;

  const UserProfileScreen(
      {super.key, required this.mqttClient, required this.user});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final TextEditingController _userEmailController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  List<Mission> _userMissions = [];

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomUpperBar(
        title: 'User Profile',
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
                  Row(
                    children: [
                      const Text(
                        'Username: ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.user.username,
                          style: const TextStyle(
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
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
                              color: primaryTextColor,
                            ),
                          ),
                          Text(
                            widget.user.status
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
                              color: primaryTextColor,
                            ),
                          ),
                          Text(
                            widget.user.type
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
                        children: _buildTypeSwitchActions(widget.user),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildMissionsSection(),
                  const SizedBox(height: 20),
                  _buildEditButton(),
                ],
              ),
            ),
    );
  }

  Future<void> _fetchUserDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });
    try {
      await widget.user.fetchUserDetails(() {
        if (mounted) {
          setState(() {
            _userEmailController.text =
                widget.user.email ?? 'No email available';
            _userMissions = widget.user.missions ?? [];
            print('user object ${widget.user}');
          });
        }
      });
    } catch (error) {
      print("Failed to fetch user's details: $error");
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildMissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Missions:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        _userMissions.isEmpty
            ? const Text(
                'No missions assigned',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                ),
              )
            : Column(
                children: _userMissions.map((mission) {
                  return ListTile(
                    title: Text(
                      mission.name,
                      style: const TextStyle(color: secondaryTextColor),
                    ),
                    trailing: (widget.user.status == UserStatus.ASSIGNED) &&
                            !_isEditing
                        ? _buildMonitorButton(mission)
                        : const SizedBox.shrink(),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildMonitorButton(Mission mission) {
    if (!_isEditing && mission.status == MissionStatus.ONGOING) {
      return ElevatedButton(
        onPressed: () {
          // Navigate to the mission monitoring screen
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MissionDevicesListScreen(
                  mission: mission,
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
          ElevatedButton(
            onPressed: () {
              _showApprovalDialog(user.user_id);
            },
            child: const Text('Approve'),
          ),
          const SizedBox(width: 5),
          ElevatedButton(
            onPressed: () {
              _rejectUser(user.user_id);
            },
            child: const Text('Reject'),
          ),
        ];
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
      case UserStatus.INACTIVE:
        return [];
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
    if (widget.user.status == UserStatus.REJECTED ||
        widget.user.status == UserStatus.INACTIVE ||
        widget.user.status == UserStatus.PENDING) {
      // If user status is REJECTED or INACTIVE, return an empty container
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
      final String newEmail = _userEmailController.text;

      // Build the update data
      final Map<String, dynamic> updateData = {};

      if (newEmail != widget.user.email) {
        updateData['email'] = newEmail;
      }

      if (updateData.isNotEmpty) {
        // Call update user API only if there are changes
        await AdminApiService.updateUser(
          user_id: userId,
          email: updateData['email'],
        );
        await _fetchUserDetails();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User updated successfully'),
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
          content: Text('Failed to update user: $e'),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Widget> _buildTypeSwitchActions(User user) {
    if (widget.user.status != UserStatus.INACTIVE &&
        widget.user.status != UserStatus.PENDING &&
        widget.user.status != UserStatus.REJECTED) {
      switch (user.type) {
        case UserType.ADMIN:
          return [
            ElevatedButton(
              onPressed: () async {
                await AdminApiService.updateUser(
                  user_id: widget.user.user_id,
                  type: UserType.REGULAR,
                );
                await _fetchUserDetails();
              },
              child: const Text('Switch to Regular'),
            ),
            const SizedBox(width: 5),
          ];
        default:
          return [
            ElevatedButton(
              onPressed: () async {
                await AdminApiService.updateUser(
                  user_id: widget.user.user_id,
                  type: UserType.ADMIN,
                );
                await _fetchUserDetails();
              },
              child: const Text('Switch to Admin'),
            ),
          ];
      }
    } else {
      return [];
    }
  }
}
