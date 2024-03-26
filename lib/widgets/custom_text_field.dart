import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final IconData prefixIcon;
  final TextEditingController? controller;
  final bool? obscureText;
  final String? errorText;
  final ValueChanged<String>? onChanged; // Define onChanged parameter

  CustomTextField({
    required this.hintText,
    required this.prefixIcon,
    this.controller,
    this.obscureText,
    this.errorText,
    this.onChanged, // Add onChanged parameter
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          style: const TextStyle(color: Colors.white),
          controller: controller,
          obscureText: obscureText ?? false,
          onChanged: onChanged, // Pass onChanged callback to TextField
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white70),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            fillColor: const Color(0xff293038),
            filled: true,
            prefixIcon: Icon(prefixIcon, color: Colors.white70),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              errorText!,
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }
}
