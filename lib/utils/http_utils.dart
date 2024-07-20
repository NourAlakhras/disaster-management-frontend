import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_3/services/auth_api_service.dart';
import 'package:flutter_3/utils/constants.dart';
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
    final Uri url = Uri.parse('$webServerBaseUrl$endpoint');
    String? token = await AuthApiService.getAuthToken();
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      http.Response response;
      switch (method) {
        case 'POST':
          response = await http
              .post(url, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 10));
          break;
        case 'PUT':
          response = await http
              .put(url, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 10));
          break;
        case 'GET':
          response = await http
              .get(url, headers: headers)
              .timeout(const Duration(seconds: 10));
          break;
        case 'DELETE':
          response = await http
              .delete(url, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 10));
          break;
        default:
          throw Exception('Unsupported HTTP method');
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
}
