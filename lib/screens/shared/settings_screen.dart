import 'package:flutter/material.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/services/user_api_service.dart';

class SettingsScreen extends StatefulWidget {
  final MQTTClientWrapper mqttClient;

  const SettingsScreen({super.key, required this.mqttClient});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<Map<String, dynamic>> _userDataFuture;
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserSettingsDetails();
  }

  Future<void> _fetchUserSettingsDetails() async {
    try {
      final userDetails = await UserApiService.getUserInfo();
      print('userDetails $userDetails');
      setState(() {
        _userNameController.text = userDetails.username;
        _userEmailController.text = userDetails.email!;
      });
    } catch (e) {
      print('Error fetching mission info: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await widget.mqttClient.logout();
      await UserApiService.logout();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    } catch (e) {
      print('Failed to logout: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xff121417),
        appBar: CustomUpperBar(
          title: 'Settings',
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
            :Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
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
                  _buildEditButton(),
                  _buildChangePasswordButton(),
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
              )));
  }

  Widget _buildEditButton() {
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

  void _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String username = _userNameController.text;
      final String email = _userEmailController.text;

      // Call updateuser API
      await UserApiService.updateUserInfo(username: username, email: email);
      await _fetchUserSettingsDetails();

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

  Widget _buildChangePasswordButton() {
    return ElevatedButton(
      onPressed: () => _showChangePasswordDialog(),
      child: const Text('Change Password'),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _oldPasswordController,
                decoration: const InputDecoration(labelText: 'Old Password'),
                obscureText: true,
              ),
              TextField(
                controller: _newPasswordController,
                decoration: const InputDecoration(labelText: 'New Password'),
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
                _changePassword();
                Navigator.of(context).pop();
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePassword() async {
    String oldPassword = _oldPasswordController.text;
    String newPassword = _newPasswordController.text;

    if (oldPassword.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both passwords'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await UserApiService.updatePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to change password: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _oldPasswordController.clear();
        _newPasswordController.clear();
      });
    }
  }
}
