import 'package:flutter/material.dart';
import 'package:flutter_3/widgets/custom_button.dart';
import 'package:gap/gap.dart';
import 'package:flutter_3/utils/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Gap(screenHeight * 0.05),
                          Image.asset(
                            'assets/images/logo.png', 
                            height: screenHeight * 0.3, 
                          ),
                          Gap(screenHeight * 0.03),
                          const Text(
                            'Disaster Management & Recovery System',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Gap(screenHeight * 0.03),
                          const Text(
                            'Sponsored by PSDSARC',
                            style: TextStyle(
                              fontSize: 24.0,
                              color: secondaryTextColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          CustomButton(
                            text: "Signup",
                            onPressed: () {
                              Navigator.pushNamed(context, '/signup');
                            },
                          ),
                          Gap(screenHeight * 0.02),
                          CustomButton(
                            text: "Login",
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            ButtonBackgroundColor:
                                barColor, // Example: Set background color to blue
                          ),
                          Gap(screenHeight * 0.03),
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
