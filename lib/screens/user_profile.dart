import 'package:flutter/material.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/models/user_credentials.dart';
import 'package:flutter_3/screens/mission_devices_base_screen.dart';
import 'package:flutter_3/services/admin_api_service.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/confirmation_dialog.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/utils/app_colors.dart';

class UserProfileScreen extends StatefulWidget {
  final User user;

  const UserProfileScreen({super.key, required this.user});

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
      await widget.user.fetchUserDetails(
          context: context,
          setStateCallback: () {
            if (mounted) {
              setState(() {
                _userEmailController.text =
                    widget.user.email ?? 'No email available';
                _userMissions = widget.user.missions ?? [];
                print('user object ${widget.user}');
              });
            }
          });
    } catch (e) {
      print('Failed to fetch user details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                builder: (context) => MissionDevicesBaseScreen(
                  mission: mission,
                ),
              ));
        },
        child: const Text('Monitor Mission'),
      );
    } else {
      return const SizedBox();
    }
  }

  Future<void> _showApprovalDialog(User user) async {
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
                _approveUser(user, isAdmin: true);
              },
              child: const Text('Admin'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _approveUser(user, isAdmin: false);
              },
              child: const Text('Regular User'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _approveUser(User user, {required bool isAdmin}) async {
    try {
      await user.approve(
          context: context,
          isAdmin: isAdmin,
          setStateCallback: () {
            setState(() {});
          });
    } catch (error) {
      print('Failed to approve user: $error');
    }
  }

  Widget _buildActionButton(
    String label,
    Future<void> Function() action,
  ) {
    return ElevatedButton(
      onPressed: () async {
        try {
          await action();
        } catch (e) {
          print('Failed to perform action: $e');
        } finally {
          setState(() {});
        }
      },
      child: Text(label),
    );
  }

  Future<void> _handleDeleteUser(User user) async {
    // Check if the user is trying to delete their own account
    if (widget.user.user_id == user.user_id) {
      final bool confirmed = await showConfirmationDialog(
        context: context,
        title: 'Delete Account',
        message:
            'You cannot delete your own account. Are you sure you want to proceed?',
        confirmText: 'Yes, Proceed',
        cancelText: 'Cancel',
      );

      if (confirmed) {
        // Handle deletion logic here
        await _deleteUser();
      }
    } else {
      final bool confirmed = await showConfirmationDialog(
        context: context,
        title: 'Delete Account',
        message: 'Are you sure you want to delete this user?',
        confirmText: 'Delete',
        cancelText: 'Cancel',
      );

      if (confirmed) {
        await _deleteUser();
      }
    }
  }

  Future<void> _deleteUser() async {
    try {
      await widget.user.delete(
          context: context,
          setStateCallback: () {
            setState(() {}); // Refresh state after deletion
          });

      Navigator.pop(context, true); // Pop with a result indicating success
    } catch (e) {
      print('Failed to delete user: $e');
    }
  }

  List<Widget> _buildUserActions(User user) {
    if (UserCredentials().getUserType() == UserType.ADMIN) {
      final actions = <Widget>[];

      switch (user.status) {
        case UserStatus.PENDING:
          actions.addAll([
            _buildActionButton('Approve', () => _showApprovalDialog(user)),
            _buildActionButton(
                'Reject',
                () => user.reject(
                    context: context,
                    setStateCallback: () {
                      setState(() {}); // Refresh state after rejection
                    })),
          ]);
          break;

        case UserStatus.REJECTED:
          actions.addAll([
            _buildActionButton('Approve', () => _showApprovalDialog(user)),
          ]);
          break;

        case UserStatus.AVAILABLE:
        case UserStatus.ASSIGNED:
          actions.addAll([
            _buildActionButton(
                'Delete', () => _handleDeleteUser(user)), // Use the new method
          ]);
          break;

        case UserStatus.INACTIVE:
          // No actions for inactive users
          break;

        default:
          break;
      }

      return actions;
    }

    return [];
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
          context: context,
          user_id: userId,
          email: updateData['email'],
        );
        await _fetchUserDetails();
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
      print('Failed to update user: $e');
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
                  context: context,
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
                  context: context,
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
