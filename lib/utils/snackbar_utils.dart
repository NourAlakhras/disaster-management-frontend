// lib/utilities/snackbar_utils.dart

import 'package:flutter/material.dart';
import 'package:flutter_3/utils/app_colors.dart';

class SnackbarUtils {
  static void showSnackBar(BuildContext context, String message,
      {Color backgroundColor = const Color(0xFFB71C1C)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
}
