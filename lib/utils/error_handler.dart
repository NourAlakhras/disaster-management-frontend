import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void handleErrorResponse(BuildContext context, http.Response response) {
  final responseBody = jsonDecode(response.body);
  final errorMessage = responseBody['message'] ?? 'Unknown error';
  print('Error: $errorMessage');

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(errorMessage),
      backgroundColor: Colors.red,
    ),
  );
}
