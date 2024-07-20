import 'package:flutter/material.dart';
import 'package:flutter_3/models/user_credentials.dart';
import 'package:flutter_3/services/auth_api_service.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/services/user_api_service.dart';
import 'package:flutter_3/utils/app_colors.dart';

class SettingsScreen extends StatefulWidget {


  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final MQTTClientWrapper mqttClientWrapper =
      MQTTClientWrapper(); // Access singleton instance

  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool isEmailValid = true;
  bool isUsernameValid = true;
  bool isPasswordValid = true;
  bool isConfirmPasswordValid = true;
  bool _isEditing = false;
  bool _isLoading = false;
  final credentials = UserCredentials();

  @override
  void initState() {
    super.initState();
    _fetchUserSettingsDetails();
  }

  Future<void> _fetchUserSettingsDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userDetails = await UserApiService.getUserInfo(context: context);
      print('userDetails $userDetails');
      setState(() {
        _userNameController.text = userDetails.username;
        _userEmailController.text = userDetails.email!;
      });
    } catch (e) {
      print('Error fetching user info: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateConnection() async {
    try {
      await mqttClientWrapper.updateConnection(); // Use the singleton instance
      // Show success message or handle UI updates as needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection updated successfully.')),
      );
    } catch (e, stackTrace) {
      print('Error in update connection: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update connection.')),
      );
    }
  }

  Future<void> _logout() async {
    try {
      mqttClientWrapper.logout(); // Use the singleton instance
      await AuthApiService.clearToken();
      UserCredentials().clearUserCredentials();

      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e, stackTrace) {
      print('Error in logout: $e');
      print('Stack trace: $stackTrace');
      // Handle error as needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to logout.')),
      );
    }
  }

  void _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String username = _userNameController.text;
      final String email = _userEmailController.text;

      await UserApiService.updateUserInfo(
          username: username, email: email, context: context);
      await _fetchUserSettingsDetails();

      credentials.setUserCredentials(
          username, credentials.password, credentials.userType);

      _updateConnection();
    } catch (e) {
      print('Failed to update user info: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String oldPassword = _oldPasswordController.text;
      String newPassword = _newPasswordController.text;

      // Check if the new password is the same as the old password
      if (oldPassword == newPassword) {
        print(
            'New password is the same as the old password. Skipping API call.');
        return; // Exit the method early
      }
      await UserApiService.updatePassword(
        context: context,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      credentials.setUserCredentials(
          credentials.username, newPassword, credentials.userType);

      _updateConnection();
    } catch (e) {
      print('Failed to change password: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required Function(String) onChanged,
    required String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                      onChanged: onChanged,
                      decoration: InputDecoration(
                        errorText: errorText,
                        errorStyle: const TextStyle(color: errorColor),
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
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              errorText!,
              style: const TextStyle(color: errorColor),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomUpperBar(
        title: 'Settings',
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
          : LayoutBuilder(
              builder: (context, constraints) {
                double screenHeight = constraints.maxHeight;
                double screenWidth = constraints.maxWidth;

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.08),
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(height: screenHeight * 0.07),
                            _buildEditableField(
                              label: 'Username',
                              controller: _userNameController,
                              isEditing: _isEditing,
                              onChanged: (value) {
                                setState(() {
                                  isUsernameValid = _validateUsername(value);
                                });
                              },
                              errorText:
                                  isUsernameValid ? null : 'Invalid username',
                            ),
                            const SizedBox(height: 8),
                            _buildEditableField(
                              label: 'Email',
                              controller: _userEmailController,
                              isEditing: _isEditing,
                              onChanged: (value) {
                                setState(() {
                                  isEmailValid = _validateEmail(value);
                                });
                              },
                              errorText: isEmailValid ? null : 'Invalid email',
                            ),
                            _buildEditButton(),
                            _buildChangePasswordButton(),
                            const SizedBox(height: 20),
                            const Text(
                              'Log Out',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ListTile(
                              title: const Text(
                                'Log Out',
                                style: TextStyle(color: primaryTextColor),
                              ),
                              leading: const Icon(Icons.logout,
                                  color: secondaryTextColor),
                              onTap: () async {
                                // Perform logout and navigation
                                await _logout(); // Wait for logout to complete
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _userEmailController.dispose();
    _userNameController.dispose();
    _newPasswordController.dispose();
    _oldPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildEditButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: ElevatedButton(
        onPressed: () {
          if (_isEditing) {
            if (_validateForm()) {
              _saveChanges();
            }
          }
          setState(() {
            _isEditing = !_isEditing;
          });
        },
        child: Text(_isEditing ? 'Save' : 'Edit'),
      ),
    );
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
          title: const Text('Change Password',
              style: TextStyle(color: accentColor)),
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
                onChanged: (value) {
                  setState(() {
                    isPasswordValid = _validatePassword(value);
                  });
                },
              ),
              if (!isPasswordValid)
                const Text(
                  'Invalid password',
                  style: TextStyle(color: errorColor),
                ),
              TextField(
                controller: _confirmPasswordController,
                decoration:
                    const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                onChanged: (value) {
                  setState(() {
                    isConfirmPasswordValid = _validateConfirmPassword(
                        _newPasswordController.text, value);
                  });
                },
              ),
              if (!isConfirmPasswordValid)
                const Text(
                  'Passwords do not match',
                  style: TextStyle(color: errorColor),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: accentColor)),
            ),
            ElevatedButton(
              onPressed: () {
                if (isPasswordValid && isConfirmPasswordValid) {
                  _changePassword();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
  }

  bool _validateForm() {
    bool isValid = true;

    if (!_validateEmail(_userEmailController.text)) {
      isValid = false;
      setState(() {
        isEmailValid = false;
      });
    }

    if (!_validateUsername(_userNameController.text)) {
      isValid = false;
      setState(() {
        isUsernameValid = false;
      });
    }

    return isValid;
  }

  bool _validateEmail(String value) {
    const emailRegex = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    return RegExp(emailRegex).hasMatch(value);
  }

  bool _validateUsername(String value) {
    return value.isNotEmpty;
  }

  bool _validatePassword(String value) {
    // Add your password validation logic here
    return value.length >= 6;
  }

  bool _validateConfirmPassword(String password, String confirmPassword) {
    return password == confirmPassword;
  }
}
