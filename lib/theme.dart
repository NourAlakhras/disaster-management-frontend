import 'package:flutter/material.dart';

// Define your colors
const Color primaryColor = Color(0xff06141b);
const Color secondaryColor = Color(0xff11212d);
const Color accentColor = Color(0xff253745);
const Color lightColor = Color(0xff11212d);
const Color darkColor = Color(0xff11212d);

final ThemeData myTheme = ThemeData(
  // Define primary color
  primaryColor: primaryColor,

  // Define secondary color

  // Define scaffold background color
  scaffoldBackgroundColor: lightColor,

  // Define text theme
  textTheme: const TextTheme(
    // Define headline1 color
    displayLarge: TextStyle(color: darkColor),

    // Define headline2 color
    displayMedium: TextStyle(color: darkColor),

    // Define headline3 color
    displaySmall: TextStyle(color: darkColor),

    // Define headline4 color
    headlineMedium: TextStyle(color: darkColor),

    // Define headline5 color
    headlineSmall: TextStyle(color: darkColor),

    // Define headline6 color
    titleLarge: TextStyle(color: darkColor),

    // Define bodyText1 color
    bodyLarge: TextStyle(color: darkColor),

    // Define bodyText2 color
    bodyMedium: TextStyle(color: darkColor),

    // Define subtitle1 color
    titleMedium: TextStyle(color: darkColor),

    // Define subtitle2 color
    titleSmall: TextStyle(color: darkColor),
  ),
);
