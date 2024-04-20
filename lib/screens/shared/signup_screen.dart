// lib\screens\signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_3/screens/shared/welcome_screen.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/custom_text_field.dart';
import 'package:flutter_3/widgets/custom_button.dart';
import 'package:gap/gap.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/services/user_api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

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
    try {
      await UserApiService.signUp(email, password, username);

      // Show a dialog with a message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Signup Successful'),
            content: Text(
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
                          WelcomeScreen(), // Navigate to the welcome screen
                    ),
                  );
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Signup failed: $e')));
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
    return value.isNotEmpty && value.length >= 2;
  }

  bool _validatePassword(String value) {
    return value.isNotEmpty && value.length >= 8;
  }

  bool _validateConfirmPassword(String password, String confirmPassword) {
    return password == confirmPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121417),
      appBar: CustomUpperBar(
        title: 'Sign Up',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color.fromARGB(255, 255, 255, 255),
          onPressed: () {
            Navigator.pushNamed(context, '/');
          },
        ),
      ),
      body: SingleChildScrollView(
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
                      style: TextStyle(fontSize: 24.0, color: Colors.white),
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
                    obscureText: true,
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
                    obscureText: true,
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
                          style: TextStyle(color: Colors.white54),
                        ),
                        TextSpan(
                          text: "Terms of Use",
                          style: TextStyle(
                            color: Colors.white,
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
                        style: TextStyle(color: Colors.white54)),
                    TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(color: Colors.white),
                        ))
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
