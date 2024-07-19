import 'package:flutter/material.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/models/user_credentials.dart';
import 'package:flutter_3/screens/missions_list_screen.dart';
import 'package:flutter_3/screens/dashboard_screen.dart';
import 'package:flutter_3/screens/users_list_screen.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/screens/devices_list_screen.dart';
import 'package:flutter_3/utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  final MQTTClientWrapper mqttClient;

  const HomeScreen({required this.mqttClient, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  final PageController _pageController = PageController(initialPage: 0);

  List<Mission> usermissions = [];
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userType = UserCredentials().getUserType();

    final adminItems = [
      const CurvedNavigationBarItem(
          child: Icon(Icons.dashboard, color: primaryTextColor),
          label: 'Dashboard',
          labelStyle: TextStyle(color: primaryTextColor)),
      const CurvedNavigationBarItem(
          child: Icon(Icons.account_circle, color: primaryTextColor),
          label: 'Users',
          labelStyle: TextStyle(color: primaryTextColor)),
      const CurvedNavigationBarItem(
          child: Icon(Icons.access_alarm_outlined, color: primaryTextColor),
          label: 'Missions',
          labelStyle: TextStyle(color: primaryTextColor)),
      const CurvedNavigationBarItem(
          child: Icon(Icons.android, color: primaryTextColor),
          label: 'Devices',
          labelStyle: TextStyle(color: primaryTextColor)),
    ];

    final userItems = [
      const CurvedNavigationBarItem(
          child: Icon(Icons.dashboard, color: primaryTextColor),
          label: 'Dashboard',
          labelStyle: TextStyle(color: primaryTextColor)),
      const CurvedNavigationBarItem(
          child: Icon(Icons.access_alarm_outlined, color: primaryTextColor),
          label: 'Missions',
          labelStyle: TextStyle(color: primaryTextColor)),
    ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        bottomNavigationBar: CurvedNavigationBar(
          key: _bottomNavigationKey,
          index: 0,
          items: userType == UserType.ADMIN ? adminItems : userItems,

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
          backgroundColor:
              Colors.transparent, // Background color of the navigation bar
          color: barColor, // Color of the icons and text
          buttonBackgroundColor:
              barColor, // Background color of the selected item
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {});
          },
          physics: NeverScrollableScrollPhysics(), // Disable default swipe

          children: userType == UserType.ADMIN
              ? [
                  Center(child: DashboardScreen(mqttClient: widget.mqttClient)),
                  Center(child: UsersListScreen(mqttClient: widget.mqttClient)),
                  Center(
                      child: MissionsListScreen(mqttClient: widget.mqttClient)),
                  Center(
                      child: DevicesListScreen(mqttClient: widget.mqttClient)),
                ]
              : [
                  Center(child: DashboardScreen(mqttClient: widget.mqttClient)),
                  Center(
                      child: MissionsListScreen(mqttClient: widget.mqttClient)),
                ],
        ),
      ),
    );
  }
}
