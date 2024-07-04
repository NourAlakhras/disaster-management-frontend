import 'package:flutter/material.dart';
import 'package:flutter_3/utils/app_colors.dart';

class CustomTheme {
  static ThemeData get darkTheme {
    return ThemeData(

      hoverColor:accentColor,
      disabledColor: secondaryTextColor,
      highlightColor:accentColor,
      dialogBackgroundColor: secondaryTextColor,
      hintColor: accentColor,
      primaryColor: accentColor,
      scaffoldBackgroundColor: backgroundColor,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: accentColor,
        selectionColor: accentColor,
        selectionHandleColor: accentColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryTextColor,
          foregroundColor: accentColor,
          textStyle: const TextStyle(
            color: accentColor,
          ),
        ),
      ),
      dividerColor: accentColor,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentColor, // Color of CircularProgressIndicator
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: accentColor, // Default button color
        textTheme: ButtonTextTheme.primary,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        floatingLabelStyle:TextStyle(color: accentColor),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accentColor),
        ),
        // labelStyle: TextStyle(color: accentColor), // Label color when focused
      ),
      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateColor.resolveWith(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return accentColor; // Selected checkbox color
            }
            return Colors.transparent; // Default fill color
          },
        ),
        checkColor: MaterialStateColor.resolveWith(
          (Set<MaterialState> states) {
            return accentColor; // Color of the checkmark icon
          },
        ),
      ),
      // Radio button theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateColor.resolveWith(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return accentColor; // Selected radio button color
            }
            return Colors.transparent; // Default fill color
          },
        ),
      ),
      // Dropdown theme (dropdown arrow color)
      iconTheme: const IconThemeData(color: primaryTextColor),
      dialogTheme: DialogTheme(
        titleTextStyle: const TextStyle(
            color: primaryTextColor, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: const TextStyle(color: accentColor),
        backgroundColor: secondaryTextColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        // Define other properties like button styles if needed
      ),
    );
  }
}
