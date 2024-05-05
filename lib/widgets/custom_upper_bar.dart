import 'package:flutter/material.dart';

class CustomUpperBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget leading;
  final List<Widget> actions;
  final Color backgroundColor;

  const CustomUpperBar({
    Key? key,
    required this.title,
    this.leading = const SizedBox(),
    this.actions = const [],
    this.backgroundColor = const Color(0xff121417), // Assign default value
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor, // Use backgroundColor field
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      leading: leading,
      actions: actions,
      elevation: 0.0,
    );
  }

  @override
  Size get preferredSize => AppBar().preferredSize;
}
