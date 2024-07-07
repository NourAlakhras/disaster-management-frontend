// lib\screens\signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_3/screens/shared/welcome_screen.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/custom_text_field.dart';
import 'package:flutter_3/widgets/custom_button.dart';
import 'package:gap/gap.dart';
import 'package:flutter_3/services/user_api_service.dart';
import 'package:flutter_3/utils/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  String get email => _emailController.text;
  String get username => _usernameController.text;
  String get password => _passwordController.text;
  String get confirmPassword => _confirmPasswordController.text;

  bool isEmailValid = true;
  bool isUsernameValid = true;
  bool isPasswordValid = true;
  bool isConfirmPasswordValid = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await UserApiService.signUp(email, password, username);

      // Show a dialog with a message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Signup Successful'),
            content: const Text(
              'You have successfully signed up. Please wait for admin approval to log in.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const WelcomeScreen(), // Navigate to the welcome screen
                    ),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Signup failed: $e'),
        backgroundColor: errorColor,
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateForm() {
    return isEmailValid &&
        isUsernameValid &&
        isPasswordValid &&
        isConfirmPasswordValid;
  }

  bool _validateEmail(String value) {
    return value.isNotEmpty &&
        value.contains('@') &&
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
  }

  bool _validateUsername(String value) {
    return value.isNotEmpty && value.length >= 3 && value.length <= 20;
  }

  bool _validatePassword(String value) {
    return value.isNotEmpty &&
        value.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(value) && // Uppercase letter
        RegExp(r'[a-z]').hasMatch(value) && // Lowercase letter
        RegExp(r'[0-9]').hasMatch(value) && // Digit
        RegExp(r'[!@#\$&*~]').hasMatch(value); // Special character
  }

  bool _validateConfirmPassword(String password, String confirmPassword) {
    return password == confirmPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomUpperBar(
        title: 'Sign Up',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: primaryTextColor,
          onPressed: () {
            Navigator.pushNamed(context, '/');
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              height: MediaQuery.of(context).size.height,
              // width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      const Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          "Create your account",
                          style: TextStyle(
                              fontSize: 24.0, color: primaryTextColor),
                        ),
                      ),
                      const Gap(40),
                      CustomTextField(
                        hintText: "Email",
                        prefixIcon: Icons.email,
                        controller: _emailController,
                        onChanged: (value) {
                          setState(() {
                            isEmailValid = _validateEmail(value);
                          });
                        },
                        errorText: isEmailValid ? null : 'Invalid email',
                      ),
                      const Gap(20),
                      CustomTextField(
                        hintText: "Username",
                        prefixIcon: Icons.account_circle,
                        controller: _usernameController,
                        onChanged: (value) {
                          setState(() {
                            isUsernameValid = _validateUsername(value);
                          });
                        },
                        errorText: isUsernameValid ? null : 'Invalid username',
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
                      const Gap(20),
                      CustomTextField(
                        hintText: "Confirm Password",
                        prefixIcon: Icons.lock,
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                        onChanged: (value) {
                          setState(() {
                            isConfirmPasswordValid =
                                _validateConfirmPassword(password, value);
                          });
                        },
                        errorText: isConfirmPasswordValid
                            ? null
                            : 'Passwords do not match',
                      ),
                      const Gap(40),
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: "By continuing, you agree to the ",
                              style: TextStyle(color: secondaryTextColor),
                            ),
                            TextSpan(
                              text: "Terms of Use",
                              style: TextStyle(
                                color: primaryTextColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(15),
                      CustomButton(
                        text: "Sign up",
                        onPressed: () {
                          if (_validateForm()) {
                            _signUp(context);
                          }
                        },
                      ),
                    ],
                  ),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text("Already have an account?",
                            style: TextStyle(color: secondaryTextColor)),
                        TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: const Text(
                              "Login",
                              style: TextStyle(color: primaryTextColor),
                            ))
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
