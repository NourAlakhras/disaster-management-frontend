import 'package:flutter/material.dart';
import 'package:flutter_3/utils/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color ButtonBackgroundColor;
  final Color textColor;

  const CustomButton({
    required this.text,
    required this.onPressed,
    this.ButtonBackgroundColor = accentColor,
    this.textColor = secondaryTextColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              // ignore: unnecessary_this
              cardColor,
              ButtonBackgroundColor,
            ], // Replace with your gradient colors
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.07),
              spreadRadius: 2,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors
                .transparent, // Transparent background to see the gradient
            padding: const EdgeInsets.symmetric(vertical: 8),
            elevation: 0, // No shadow
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: Text(
            text,
            style: TextStyle(fontSize: 20, color: textColor),
          ),
        ),
      ),
    );
  }
}
