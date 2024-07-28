import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:flutter_3/utils/constants.dart';
import 'package:flutter_3/utils/shared_preferences_utils.dart';
import 'package:http/http.dart' as http;
import 'error_utils.dart';
import 'snackbar_utils.dart';
import 'app_colors.dart'; // Make sure to import your colors file if needed

class HttpUtils {
  static const String webServerBaseUrl = Constants.webServerBaseUrl;

  static Future<Map<String, dynamic>> makeRequest({
    required BuildContext context,
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    final Uri initialUrl = Uri.parse('$webServerBaseUrl$endpoint');
    String? token = await SharedPreferencesUtils.getAuthToken();
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      http.Response response = await _performRequest(
        method: method,
        url: initialUrl,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 308) {
        String? newUrl = response.headers['location'];
        if (newUrl != null) {
          response = await _performRequest(
            method: method,
            url: Uri.parse(newUrl),
            headers: headers,
            body: body,
          );
        }
      }

      final responseBody = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        if (context.mounted) {
          ErrorUtils.handleErrorResponse(context, response);
        }
        throw Exception(
            'Failed to perform $method request: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      if (context.mounted) {
        SnackbarUtils.showSnackBar(
          context,
          'Request timed out. Please try again later.',
          backgroundColor: errorColor,
        );
      }
      throw Exception('Request timed out: $e');
    } on FormatException catch (e) {
      if (context.mounted) {
        SnackbarUtils.showSnackBar(
          context,
          'Unexpected response format: $e',
          backgroundColor: errorColor,
        );
      }
      throw Exception('Unexpected response format: $e');
    } catch (e, stackTrace) {
      print('Unexpected error occurred: $e\n$stackTrace');
      throw Exception('Unexpected error occurred: $e');
    }
  }

  static Future<http.Response> _performRequest({
    required String method,
    required Uri url,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) async {
    switch (method) {
      case 'POST':
        return await http
            .post(url, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 10));
      case 'PUT':
        return await http
            .put(url, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 10));
      case 'GET':
        return await http
            .get(url, headers: headers)
            .timeout(const Duration(seconds: 10));
      case 'DELETE':
        return await http
            .delete(url, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 10));
      default:
        throw Exception('Unsupported HTTP method');
    }
  }
}
