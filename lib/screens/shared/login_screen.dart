import 'package:flutter/material.dart';
import 'package:flutter_3/screens/shared/home_screen.dart';
import 'package:flutter_3/services/auth_api_service.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/utils/exceptions.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/custom_text_field.dart';
import 'package:flutter_3/widgets/custom_button.dart';
import 'package:gap/gap.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/services/user_api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_3/utils/app_colors.dart';

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

// Helper method to convert integer type to UserType enum
  UserType _getUserType(int typeValue) {
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

      final Map<String, dynamic> responseData =
          await UserApiService.login(emailOrUsername, password);
      print('responseData $responseData');

      // Extract data from the response
      final String username = responseData['username'];
      final String token = responseData['token'];
      final UserType userType = _getUserType(responseData['type']);

      // Cache the token
      await AuthApiService.cacheToken(token);

      // Set user credentials globally
      final credentials = UserCredentials();

      // credentials.setUserCredentials(username, password,userType);
      credentials.setUserCredentials(
          'test-mobile-app', 'Test-mobile12', userType);

      // Connect to MQTT broker
      await _mqttClient.prepareMqttClient();

      // Navigate to the home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(mqttClient: _mqttClient),
        ),
      );
    } catch (e) {
      String errorMessage = 'Login failed: ${e.toString()}';
      if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is UnauthorizedException) {
        errorMessage = e.message;
      } else if (e is ForbiddenException) {
        errorMessage = e.message;
      } else if (e is InternalServerErrorException) {
        errorMessage = e.message;
      } else if (e is NotFoundException) {
        errorMessage = e.message;
      } else if (e is ConflictException) {
        errorMessage = e.message;
      } else if (e.toString().contains('No internet connection')) {
        errorMessage =
            'No internet connection. Please check your connection and try again.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Future<void> _login(BuildContext context) async {
  //   try {
  //     final Map<String, dynamic> responseData =
  //         await UserApiService.login(emailOrUsername, password);
  //     final String username = responseData['username'];
  //     // final bool isAdmin = responseData['admin'] ?? false; // Get admin status

  //     // Set user credentials globally
  //     final credentials = UserCredentials();
  //     credentials.setUserCredentials(username, password);

  //     // Connect to MQTT broker
  //     await _mqttClient.prepareMqttClient();

  //     // Navigate to the appropriate screen based on admin status
  //     if (isAdmin) {
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) =>
  //               AdminHomeScreen(), // Redirect to AdminHomeScreen
  //         ),
  //       );
  //     } else {
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => HomeScreen(mqttClient: _mqttClient),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text('Login failed: $e')));
  //   }
  // }

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
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Column(
                children: <Widget>[
                  const Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      "Welcome back!",
                      style: TextStyle(fontSize: 24.0, color: primaryTextColor),
                    ),
                  ),
                  const Gap(40),
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
                  const Gap(20),
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
                    errorText: isPasswordValid ? null : 'Invalid password',
                  ),
                  const Gap(40),
                  CustomButton(
                    text: "Login",
                    onPressed: () {
                      if (_validateForm()) {
                        _login(context);
                      }
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("Don't have an account?",
                      style: TextStyle(color: secondaryTextColor)),
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
            ],
          ),
        ),
      ),
    );
  }
}
