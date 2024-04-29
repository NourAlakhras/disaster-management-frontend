import 'package:flutter/material.dart';
import 'package:flutter_3/screens/shared/welcome_screen.dart';
import 'package:flutter_3/screens/shared/login_screen.dart';
import 'package:flutter_3/screens/shared/signup_screen.dart';

void main() => runApp(MaterialApp(
      theme: ThemeData(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.blueGrey, // Change cursor color here
          selectionColor: Colors.blueGrey, // Change selection color here
          selectionHandleColor:
              Colors.blueGrey, // Change selection handle color here
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.blueGrey, // Change button's overlay color when pressed
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) =>  const LoginScreen(),
        '/signup': (context) =>  const SignupScreen(),
      },
    ));
