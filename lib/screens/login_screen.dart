import 'package:flutter/material.dart';
import 'package:flutter_3/screens/home_screen.dart';

import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/utils/shared_preferences_utils.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/custom_text_field.dart';
import 'package:flutter_3/widgets/custom_button.dart';
import 'package:gap/gap.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/services/api_services/user_api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_3/utils/app_colors.dart';
import 'package:flutter_3/models/user_credentials.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailOrUsernameController;
  late TextEditingController _passwordController;
  late MQTTClientWrapper _mqttClient;

  String get emailOrUsername => _emailOrUsernameController.text;
  String get password => _passwordController.text;

  bool isEmailOrUsernameValid = true;
  bool isPasswordValid = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _emailOrUsernameController = TextEditingController();
    _passwordController = TextEditingController();
    _mqttClient = MQTTClientWrapper();
  }

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper method to convert integer type to userType enum
  UserType _getuserType(int typeValue) {
    return userTypeValues.entries
        .firstWhere((entry) => entry.value == typeValue,
            orElse: () =>
                MapEntry(UserType.REGULAR, userTypeValues[UserType.REGULAR]!))
        .key;
  }

  Future<void> _login(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('No internet connection');
      }

      final Map<String, dynamic> responseData = await UserApiService.login(
          context: context,
          emailOrUsername: emailOrUsername,
          password: password);
      print('responseData $responseData');

      // Extract data from the response
      final String userId = responseData['id'];
      final String username = responseData['username'];
      final String token = responseData['token'];
      final UserType userType = _getuserType(responseData['type']);

      // Cache the token
      await SharedPreferencesUtils.cacheToken(token);

      // Set user credentials globally
      final credentials = UserCredentials();

      credentials.setUserCredentials(
          userId: userId,
          username: username,
          password: password,
          userType: userType);

      // Connect to MQTT broker
      await _mqttClient.prepareMqttClient();

      // Navigate to the home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ),
      );
    } catch (e) {
      print('Login failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateForm() {
    return isEmailOrUsernameValid && isPasswordValid;
  }

  bool _validateEmailOrUsername(String value) {
    return value.isNotEmpty;
  }

  bool _validatePassword(String value) {
    return value.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomUpperBar(
        title: 'Login',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: primaryTextColor,
          onPressed: () {
            Navigator.pushNamed(context, '/');
          },
        ),
      ),
      body: LayoutBuilder(
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
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: screenHeight * 0.05),
                          const Text(
                            "Welcome back!",
                            style: TextStyle(
                              fontSize: 24.0,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 40),
                          CustomTextField(
                            hintText: "Email or Username",
                            prefixIcon: Icons.email,
                            controller: _emailOrUsernameController,
                            onChanged: (value) {
                              setState(() {
                                isEmailOrUsernameValid =
                                    _validateEmailOrUsername(value);
                              });
                            },
                            errorText: isEmailOrUsernameValid
                                ? null
                                : 'Empty Email or Username',
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            hintText: "Password",
                            prefixIcon: Icons.lock,
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            onChanged: (value) {
                              setState(() {
                                isPasswordValid = _validatePassword(value);
                              });
                            },
                            errorText:
                                isPasswordValid ? null : 'Invalid password',
                          ),
                          const SizedBox(height: 40),
                          CustomButton(
                            text: "Login",
                            onPressed: () {
                              if (_validateForm()) {
                                _login(context);
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Text(
                                "Don't have an account?",
                                style: TextStyle(color: secondaryTextColor),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/signup');
                                },
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(color: primaryTextColor),
                                ),
                              ),
                            ],
                          ),
                          if (_isLoading)
                            const Center(
                              child: CircularProgressIndicator(),
                            ),
                        ],
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
}
