import 'package:flutter/material.dart';
import 'package:flutter_3/utils/app_colors.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final Function() onClear;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: primaryTextColor.withOpacity(0.009),
            spreadRadius: 2,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search, color: primaryTextColor),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintStyle: TextStyle(color: secondaryTextColor),
                labelStyle: TextStyle(color: primaryTextColor),
              ),
              style: const TextStyle(color: primaryTextColor),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: primaryTextColor),
              onPressed: onClear,
            ),
          IconButton(
              icon: const Icon(Icons.filter_list, color: primaryTextColor),
              onPressed: () {
                // Open the drawer when filter icon is clicked
                Scaffold.of(context).openEndDrawer();
              })
        ],
      ),
    );
  }
}
