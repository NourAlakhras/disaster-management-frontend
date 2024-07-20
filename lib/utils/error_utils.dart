// lib/utilities/error_utils.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'snackbar_utils.dart';

class ErrorUtils {
  static void handleErrorResponse(
      BuildContext context, http.Response response) {
    final responseBody = jsonDecode(response.body);
    final errorMessage = responseBody['message'] ?? 'Unknown error';
    print('Error: $errorMessage');
    SnackbarUtils.showSnackBar(context, errorMessage);
  }
}
