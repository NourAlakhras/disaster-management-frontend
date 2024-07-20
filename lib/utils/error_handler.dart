import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void showSnackBar(BuildContext context, String message,
    {Color backgroundColor = Colors.red}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
    ),
  );
}

void handleErrorResponse(BuildContext context, http.Response response) {
  final responseBody = jsonDecode(response.body);
  final errorMessage = responseBody['message'] ?? 'Unknown error';
  print('Error: $errorMessage');
  showSnackBar(context, errorMessage);
}

Future<void> handleHttpError(
    {required BuildContext context,
    required http.Response response,
    required Function() onSuccess}) async {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    onSuccess();
  } else {
    handleErrorResponse(context, response);
    throw Exception('HTTP error: ${response.statusCode}');
  }

  
  
}
