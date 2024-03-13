import 'package:flutter/material.dart';

class TabbedView extends StatelessWidget {
  const TabbedView({
    Key? key,
    required this.length,
    required this.tabs,
    required this.tabContents,
    this.tabBarColor = Colors.white,
    this.indicatorColor = Colors.white, // Specify the default indicator color
    this.iconColor = Colors.white60, // Specify the default icon color
    this.selectedIconColor =
        Colors.white, // Specify the default selected icon color
  }) : super(key: key);

  final int length;
  final List<Widget> tabs;
  final List<Widget> tabContents;
  final Color tabBarColor;
  final Color indicatorColor;
  final Color iconColor;
  final Color selectedIconColor;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: length,
      child: Scaffold(
        backgroundColor: const Color(0xff121417),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          // preferredSize: const Size.fromHeight(74),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xff121417),
            bottom: TabBar(
              tabs: tabs,
              labelColor: selectedIconColor,
              unselectedLabelColor: iconColor,
              indicator: BoxDecoration(
                color: const Color(0xff121417),
                border: Border(
                  bottom: BorderSide(
                      color: indicatorColor,
                      width: 5.0), // Customize the underline color and width
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: tabContents, 
        ),
      ),
    );
  }
}
