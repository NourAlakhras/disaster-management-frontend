import 'package:flutter/material.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/screens/admin/missions_list_screen.dart';
import 'package:flutter_3/screens/admin/dashboard_screen.dart';
import 'package:flutter_3/screens/admin/users_list_screen.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/services/user_api_service.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/devices_list_screen.dart';
import 'package:flutter_3/screens/admin/mission_devices_base_screen.dart';

import 'package:flutter_3/models/mission.dart';

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
          child: Icon(Icons.dashboard, color: Colors.white),
          label: 'Dashboard',
          labelStyle: TextStyle(color: Colors.white)),
      const CurvedNavigationBarItem(
          child: Icon(Icons.account_circle, color: Colors.white),
          label: 'Users',
          labelStyle: TextStyle(color: Colors.white)),
      const CurvedNavigationBarItem(
          child: Icon(Icons.access_alarm_outlined, color: Colors.white),
          label: 'Missions',
          labelStyle: TextStyle(color: Colors.white)),
      const CurvedNavigationBarItem(
          child: Icon(Icons.android, color: Colors.white),
          label: 'Devices',
          labelStyle: TextStyle(color: Colors.white)),
    ];

    final userItems = [
      const CurvedNavigationBarItem(
          child: Icon(Icons.dashboard, color: Colors.white),
          label: 'Dashboard',
          labelStyle: TextStyle(color: Colors.white)),
      const CurvedNavigationBarItem(
          child: Icon(Icons.access_alarm_outlined, color: Colors.white),
          label: 'Missions',
          labelStyle: TextStyle(color: Colors.white)),
    ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        bottomNavigationBar: CurvedNavigationBar(
          key: _bottomNavigationKey,
          index: 0,
          items: userType == UserType.ADMIN ? adminItems : userItems,
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
