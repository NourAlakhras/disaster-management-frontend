import 'package:flutter/material.dart';
import 'package:flutter_3/widgets/custom_button.dart';
import 'package:gap/gap.dart';
import 'package:flutter_3/utils/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                                Image.asset(
                  'assets/images/logo.png', // Adjusted asset path
                  width: 300,
                ),
                const Gap(30),
                const Text(
                  'Disaster Management and Recovery System',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor),
                  textAlign: TextAlign.center,
                ),
                const Gap(30),
                const Text(
                  'Sponsored by PSDSARC',
                  style: TextStyle(fontSize: 16, color: secondaryTextColor),
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
                  ButtonBackgroundColor:
                      barColor, // Example: Set background color to blue
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
