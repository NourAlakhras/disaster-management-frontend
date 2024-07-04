import 'package:flutter/material.dart';
import 'package:flutter_3/utils/app_colors.dart';

class TabbedView extends StatelessWidget {
  const TabbedView({
    super.key,
    required this.length,
    required this.tabs,
    required this.tabContents,
    this.indicatorColor = accentColor,
    this.iconColor = secondaryTextColor,
    this.selectedIconColor = primaryTextColor,
  });

  final int length;
  final List<Widget> tabs;
  final List<Widget> tabContents;
  final Color indicatorColor;
  final Color iconColor;
  final Color selectedIconColor;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: length,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            bottom: TabBar(
              tabs: tabs.map((tab) {
                return Tab(
                  child: SizedBox.expand(
                    child: Center(child: tab),
                  ),
                );
              }).toList(),
              labelColor: selectedIconColor,
              unselectedLabelColor: iconColor,
              indicator: BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: indicatorColor,
                    width: 5.0,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: GestureDetector(
          onPanUpdate: (details) {
            // Do nothing, thus disabling full-screen swipe
          },
          child: TabBarView(
            physics: NeverScrollableScrollPhysics(), // Disable default swipe
            children: tabContents,
          ),
        ),
      ),
    );
  }
}
