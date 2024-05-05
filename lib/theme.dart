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
  textTheme: TextTheme(
    // Define headline1 color
    headline1: TextStyle(color: darkColor),

    // Define headline2 color
    headline2: TextStyle(color: darkColor),

    // Define headline3 color
    headline3: TextStyle(color: darkColor),

    // Define headline4 color
    headline4: TextStyle(color: darkColor),

    // Define headline5 color
    headline5: TextStyle(color: darkColor),

    // Define headline6 color
    headline6: TextStyle(color: darkColor),

    // Define bodyText1 color
    bodyText1: TextStyle(color: darkColor),

    // Define bodyText2 color
    bodyText2: TextStyle(color: darkColor),

    // Define subtitle1 color
    subtitle1: TextStyle(color: darkColor),

    // Define subtitle2 color
    subtitle2: TextStyle(color: darkColor),
  ),
);
