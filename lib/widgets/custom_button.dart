import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;

  const CustomButton({
    required this.text,
    required this.onPressed,
    this.backgroundColor = Colors.white70,
    this.textColor = const Color(0xff293038),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          // shape:  RoundedRectangleBorder( borderRadius: BorderRadius.circular(15),),
          padding: const EdgeInsets.symmetric(vertical: 8),
          backgroundColor: backgroundColor,
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 20, color: textColor),
        ),
      ),
    );
  }
}
