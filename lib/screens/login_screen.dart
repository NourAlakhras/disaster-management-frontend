import 'package:flutter/material.dart';
import 'package:flutter_3/screens/home_screen.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/custom_text_field.dart';
import 'package:flutter_3/widgets/custom_button.dart';
import 'package:gap/gap.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart'; 

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late MQTTClientWrapper _mqttClient;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _mqttClient = MQTTClientWrapper();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121417),
      appBar: CustomUpperBar(
        title: 'Login',
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
                      style: TextStyle(fontSize: 24.0, color: Colors.white),
                    ),
                  ),
                  const Gap(40),
                  CustomTextField(
                    hintText: "Email",
                    prefixIcon: Icons.email,
                    controller: _usernameController,
                  ),
                  const Gap(20),
                  CustomTextField(
                    hintText: "Password",
                    prefixIcon: Icons.lock,
                    controller: _passwordController,
                    obscureText: true,
                  ),
                  const Gap(40),
                  CustomButton(
                    text: "Login",
                    onPressed: () {
                _login();
              },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("Don't have an account?",
                      style: TextStyle(color: Colors.white54)),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(color: Colors.white),
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

  Future<bool> authenticateUser(String email, String password) async {
    // Implement your token-based authentication logic here
    // Make a request to your authentication API endpoint with email and password
    // If authentication is successful, return true; otherwise, return false

    // For demonstration, assume authentication is successful
    return true;
  }


  void _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    // perform any necessary validation
    // check if username and password are not empty

    // Connect to MQTT broker with the provided credentials
    // await _mqttClient.connect(username, password);
    await _mqttClient.connect('test-mobile-app', 'Test-mobile12');

    // Navigate to the main screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(mqttClient: _mqttClient),
      ),
    );
  }

}
