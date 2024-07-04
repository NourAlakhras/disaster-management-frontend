import 'package:flutter/material.dart';
import 'package:flutter_3/screens/admin/edit_mission_users_screen.dart';
import 'package:flutter_3/screens/shared/welcome_screen.dart';
import 'package:flutter_3/screens/shared/login_screen.dart';
import 'package:flutter_3/screens/shared/signup_screen.dart';
import 'package:flutter_3/theme.dart';
void main() => runApp(MaterialApp(
      theme: CustomTheme.darkTheme, 
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/edit_users': (context) => EditUsersScreen(),
      },
    ));

