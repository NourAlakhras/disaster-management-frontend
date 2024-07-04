import 'package:flutter/material.dart';
import 'package:flutter_3/utils/app_colors.dart';

class CustomUpperBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget leading;
  final List<Widget> actions;

  const CustomUpperBar({
    super.key,
    required this.title,
    this.leading = const SizedBox(),
    this.actions = const [],
    TabBar? bottom, // Assign default value
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent, // Use backgroundColor field
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(color: primaryTextColor),
      ),
      leading: leading,
      actions: actions,
      elevation: 0.0,
    );
  }

  @override
  Size get preferredSize => AppBar().preferredSize;
}
