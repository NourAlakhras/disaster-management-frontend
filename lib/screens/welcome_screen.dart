import 'package:flutter/material.dart';
import 'package:flutter_3/widgets/custom_button.dart';
import 'package:gap/gap.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121417),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FlutterLogo(
                  size: 100,
                ),
                Gap(30),
                Text(
                  'Disaster Management and Recovery System',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xffffffff)),
                  textAlign: TextAlign.center,
                ),
                Gap(30),
                Text(
                  'Sponsored by PSDSARC',
                  style: TextStyle(fontSize: 16, color: Color(0xffffffff)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20), // Adjust the horizontal margin here
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CustomButton(
                  text: "Signup",
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                ),
                const Gap(15),
                CustomButton(
                  text: "Login",
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  backgroundColor: const Color(
                      0xff293038), // Example: Set background color to blue
                  textColor: Colors.white70, // Example: Set text color to white
                ),
                const Gap(20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
