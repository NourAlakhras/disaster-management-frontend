import 'package:flutter/material.dart';
import 'package:flutter_3/screens/user/dashboard_screen.dart';
import 'package:flutter_3/screens/admin/devices_base_screen.dart';
import 'package:flutter_3/screens/shared/settings_screen.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';

class HomeScreen extends StatefulWidget {
  final MQTTClientWrapper mqttClient;


  const HomeScreen({required this.mqttClient, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  final PageController _pageController = PageController(initialPage: 0);
  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: 0,
        items: const [
          CurvedNavigationBarItem(
              child: Icon(Icons.dashboard, color: Colors.white),
              label: 'Dashboard',
              labelStyle: TextStyle(color: Colors.white)),
          CurvedNavigationBarItem(
              child: Icon(Icons.android, color: Colors.white),
              label: 'Robots',
              labelStyle: TextStyle(color: Colors.white)),
          CurvedNavigationBarItem(
              child: Icon(Icons.settings, color: Colors.white),
              label: 'Settings',
              labelStyle: TextStyle(color: Colors.white)),
        ],
        color: const Color(0xff293038),
        buttonBackgroundColor: const Color(0xff293038),
        backgroundColor: const Color(0xff121417),
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 600),
        
        onTap: (index) {
          setState(() {});
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
          );
        },
        letIndexChange: (index) => true,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {});
        },
        children: [
          Center(child: DashboardScreen(mqttClient: widget.mqttClient)),
          Center(child: DevicesBaseScreen(mqttClient: widget.mqttClient)),
          Center(child: SettingsScreen(mqttClient: widget.mqttClient)),
        ],
      ),
    ),);
  }
}
