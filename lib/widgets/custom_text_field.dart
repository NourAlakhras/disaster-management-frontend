import 'package:flutter/material.dart';
import 'package:flutter_3/utils/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final IconData prefixIcon;
  final TextEditingController? controller;
  final bool? obscureText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon; // Add a suffixIcon parameter

  const CustomTextField({
    required this.hintText,
    required this.prefixIcon,
    this.controller,
    this.obscureText,
    this.errorText,
    this.onChanged,
    this.suffixIcon, // Add suffixIcon to the constructor
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          style: const TextStyle(color: primaryTextColor),
          controller: controller,
          obscureText: obscureText ?? false,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: secondaryTextColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            fillColor: cardColor,
            filled: true,
            prefixIcon: Icon(prefixIcon, color: secondaryTextColor),
            suffixIcon: suffixIcon, // Add the suffix icon here
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              errorText!,
              style: const TextStyle(color: errorColor),
            ),
          ),
      ],
    );
  }
}
