import 'package:flutter/material.dart';
import 'package:flutter_3/screens/edit_mission_users_screen.dart';
import 'package:flutter_3/screens/welcome_screen.dart';
import 'package:flutter_3/screens/login_screen.dart';
import 'package:flutter_3/screens/signup_screen.dart';
import 'package:flutter_3/providers/sensor_data_provider.dart';
import 'package:flutter_3/theme.dart';
import 'package:flutter_3/utils/constants.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure Flutter is initialized before runApp()
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
     return 
      MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SensorDataProvider()),
        // Add other providers here if necessary
      ],
      child: MaterialApp(
      navigatorKey: Constants.navigatorKey,
      theme: CustomTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/edit_users': (context) => EditMissionUsersScreen(),
          },
      ),
    );
  }
}
