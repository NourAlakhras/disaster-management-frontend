import 'package:flutter/material.dart';
import 'package:flutter_3/screens/welcome_screen.dart';
import 'package:flutter_3/screens/login_screen.dart';
import 'package:flutter_3/screens/signup_screen.dart';
import 'package:flutter_3/screens/dashboard_screen.dart';
import 'package:flutter_3/screens/robots_list_screen.dart';
import 'package:flutter_3/screens/settings_screen.dart';
import 'package:flutter_3/screens/home_screen.dart';

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
        '/login': (context) =>  LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        // '/mainNavigator': (context) => HomeScreen(),
        // '/dashboard': (context) => DashboardScreen(),
        // '/robots': (context) => RobotsListScreen(),
        '/settings': (context) => SettingsScreen(),
      },
    ));
