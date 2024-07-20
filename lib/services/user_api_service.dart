import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_3/models/paginated_response.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/models/user_credentials.dart';
import 'package:flutter_3/utils/app_colors.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/services/auth_api_service.dart';
import 'package:flutter_3/utils/constants.dart';
import 'package:flutter_3/utils/exceptions.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/utils/error_handler.dart';
import 'package:flutter_3/utils/error_utils.dart';
import 'package:flutter_3/utils/http_utils.dart';
import 'package:flutter_3/utils/snackbar_utils.dart';

class UserApiService {
  static const String webServerBaseUrl = Constants.webServerBaseUrl;

  static Future<Map<String, dynamic>> signUp(
      {required BuildContext context,
      required String email,
      required String password,
      required String username}) async {
    final Map<String, dynamic> requestBody = {
      'email': email,
      'password': password,
      'username': username,
    };

    try {
      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/users/signup',
        method: 'POST',
        body: requestBody,
      );

      if (response.isNotEmpty) {
        return response;
      } else {
        throw Exception('Failed to create user.');
      }
    } on Exception catch (e) {
      print('Error during signUp: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> login(
      {required BuildContext context,
      required String emailOrUsername,
      required String password}) async {
    final Map<String, dynamic> requestBody = {
      'email_or_username': emailOrUsername,
      'password': password,
    };

    try {
      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/users/login',
        method: 'POST',
        body: requestBody,
      );

      if (response.isNotEmpty) {
        final String token = response['token'];
        await AuthApiService.cacheToken(token);
        return response;
      } else {
        throw Exception('Failed to login.');
      }
    } on Exception catch (e) {
      print('Error during login: $e');
      rethrow;
    }
  }

  static Future<User> getUserInfo({required BuildContext context}) async {
    try {
      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/users/',
        method: 'GET',
      );
      if (response.isNotEmpty) {
        return User.fromJson(response);
      } else {
        throw Exception('Failed to fetch user information.');
      }
    } on Exception catch (e) {
      print('Error during getUserInfo: $e');
      rethrow;
    }
  }

  static Future<void> updateUserInfo(
      {required BuildContext context,
      required String username,
      required String email}) async {
    try {
      final Map<String, String> body = {
        'username': username,
        'email': email,
      };

      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/users',
        method: 'PUT',
        body: body,
      );

      if (response.isNotEmpty) {
        final String message =
            response['message'] ?? 'User information updated successfully';
        SnackbarUtils.showSnackBar(context, message,
            backgroundColor: successColor);
      } else {
        throw Exception('Failed to update user information.');
      }
    } on Exception catch (e) {
      print('Error during updateUserInfo: $e');
      rethrow;
    }
  }

  static Future<void> updatePassword({
    required BuildContext context,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final Map<String, String> body = {
        'old_password': oldPassword,
        'new_password': newPassword,
      };

      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/users/password',
        method: 'PUT',
        body: body,
      );

      if (response.isNotEmpty) {
        final String message =
            response['message'] ?? 'Password updated successfully';
        SnackbarUtils.showSnackBar(context, message,
            backgroundColor: successColor);
      } else {
        throw Exception('Failed to update password.');
      }
    } on Exception catch (e) {
      print('Error during updatePassword: $e');
      rethrow;
    }
  }

  static Future<PaginatedResponse<Mission>> getCurrentMissions({
    required BuildContext context,
    int? pageNumber,
    int? pageSize,
    List<MissionStatus>? statuses,
    String? name,
  }) async {
    try {
      // Convert enums to their corresponding integer values
      final List<int>? _missionStatusValues =
          statuses?.map((s) => missionStatusValues[s]!).toList();

      final List<String> statusStrings =
          _missionStatusValues?.map((s) => s.toString()).toList() ?? [];

      print('statusStrings from getCurrentMissions: $statusStrings');
// Build query parameters
      Map<String, dynamic> queryParameters = {
        'page-number': pageNumber ?? 1,
        'page-size': pageSize ?? 6,
      };
// Add status query parameters
      if (_missionStatusValues != null && _missionStatusValues.isNotEmpty) {
        // Concatenate status values with the same key
        queryParameters['status'] = _missionStatusValues.join('&status=');
      }

      if (name != "" && name != null && name.isNotEmpty) {
        queryParameters['name'] = name;
      }

      print('queryParameters : $queryParameters');

// Convert query parameters to a list of key-value pairs
      final List<String> queryString =
          queryParameters.entries.map((e) => '${e.key}=${e.value}').toList();

// Join query parameters with '&' to form the final query string
      final String queryStringJoined = queryString.join('&');

      final Uri url = Uri.parse(
          '$webServerBaseUrl/api/users/cur_missions?$queryStringJoined');

// Print out the generated URL
      print('URL: $url');

      final String? token = await AuthApiService.getAuthToken();
      if (token == null) {
        throw UnauthorizedException();
      }

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 10));

      final responseBody = jsonDecode(response.body);
      print('mission responseBody: $responseBody');

      if (response.statusCode == 200) {
        final paginatedResponse = PaginatedResponse<Mission>.fromJson(
            responseBody, (json) => Mission.fromJson(json));
        return paginatedResponse;
      } else {
        handleErrorResponse(context, response);
        // This line will not be reached if handleErrorResponse always throws.
        // But to satisfy the Dart analyzer, we need to ensure all paths return or throw.
        throw Exception(
            "Failed to get user's current missions: ${response.statusCode}");
      }
    } on TimeoutException catch (e) {
      // Handle request timeout
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request timed out. Please try again later.'),
          backgroundColor: errorColor,
        ),
      );
      throw Exception('Request timed out: $e');
    } on FormatException catch (e) {
      // Handle unexpected response format (e.g., HTML instead of JSON)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected response format: $e'),
          backgroundColor: errorColor,
        ),
      );
      throw Exception('Unexpected response format: $e');
    } catch (e, stackTrace) {
      // Handle other errors
      print('Unexpected error occurred: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error occurred: $e'),
          backgroundColor: errorColor,
        ),
      );
      throw Exception('Unexpected error occurred: $e');
    }
  }

  static Future<int> getCurrentMissionsCount({
    required BuildContext context,
    List<MissionStatus>? statuses,
  }) async {
    try {
      // Convert enums to their corresponding integer values
      final List<int>? _missionStatusValues =
          statuses?.map((s) => missionStatusValues[s]!).toList();

      // Build query parameters
      Map<String, dynamic> queryParameters = {};

      // Add status query parameters
      if (_missionStatusValues != null && _missionStatusValues.isNotEmpty) {
        // Add each status value separately to the query parameters
        queryParameters['status'] = _missionStatusValues.join('&status=');
      }

      // Convert query parameters to a list of key-value pairs
      final List<String> queryString =
          queryParameters.entries.map((e) => '${e.key}=${e.value}').toList();

      // Join query parameters with '&' to form the final query string
      final String queryStringJoined = queryString.join('&');

      final Uri url = Uri.parse(
          '$webServerBaseUrl/api/users/cur_missions?$queryStringJoined');

      // Print out the generated URL
      print('URL: $url');

      final String? token = await AuthApiService.getAuthToken();
      if (token == null) {
        throw UnauthorizedException();
      }

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 10));

      final responseBody = jsonDecode(response.body);
      print('mission responseBody: $responseBody');

      if (response.statusCode == 200) {
        final int curMissionsCount = responseBody['cur_missions_count'] ?? 0;
        return curMissionsCount;
      } else {
        handleErrorResponse(context, response);
        // This line will not be reached if handleErrorResponse always throws.
        // But to satisfy the Dart analyzer, we need to ensure all paths return or throw.
        throw Exception(
            'Failed to get current missions count: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      // Handle request timeout
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request timed out. Please try again later.'),
          backgroundColor: errorColor,
        ),
      );
      throw Exception('Request timed out: $e');
    } on FormatException catch (e) {
      // Handle unexpected response format (e.g., HTML instead of JSON)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected response format: $e'),
          backgroundColor: errorColor,
        ),
      );
      throw Exception('Unexpected response format: $e');
    } catch (e, stackTrace) {
      // Handle other errors
      print('Unexpected error occurred: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error occurred: $e'),
          backgroundColor: errorColor,
        ),
      );
      throw Exception('Unexpected error occurred: $e');
    }
  }
}
