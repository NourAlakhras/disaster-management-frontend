import 'package:flutter/material.dart';
import 'package:flutter_3/screens/admin/dashboard_screen.dart';
import 'package:flutter_3/screens/admin/missions_list_screen.dart';
import 'package:flutter_3/screens/admin/robots_list_screen.dart';
import 'package:flutter_3/screens/admin/users_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';

class AdminHomeScreen extends StatefulWidget {
  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;


  GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  PageController _pageController = PageController(initialPage: 0);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: 0,
        items: const [
          CurvedNavigationBarItem(
              child: Icon(Icons.account_circle, color: Colors.white),
              label: 'Users',
              labelStyle: TextStyle(color: Colors.white)),
          CurvedNavigationBarItem(
              child: Icon(Icons.access_alarm_outlined, color: Colors.white),
              label: 'Missions',
              labelStyle: TextStyle(color: Colors.white)),
          CurvedNavigationBarItem(
              child: Icon(Icons.android, color: Colors.white),
              label: 'Robots',
              labelStyle: TextStyle(color: Colors.white)),
        ],
        color: Color(0xff293038),
        buttonBackgroundColor: Color(0xff293038),
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
          // Define the widgets for each screen here
          Center(child: UsersListScreen()),
          Center(child: MissionsListScreen()),
          Center(child: AdminRobotsListScreen()),
        ],
      ),
    );
  }
}
