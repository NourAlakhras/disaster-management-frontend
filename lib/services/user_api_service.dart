import 'dart:async';
import 'dart:convert';
import 'package:flutter_3/models/paginated_response.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/models/user_credentials.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/services/auth_api_service.dart';
import 'package:flutter_3/utils/constants.dart';
import 'package:flutter_3/utils/exceptions.dart';
import 'package:flutter_3/models/mission.dart';

class UserApiService {
  static const String webServerBaseUrl = Constants.webServerBaseUrl;

  static Future<Map<String, dynamic>> signUp(
      String email, String password, String username) async {
    final Uri url = Uri.parse('${Constants.webServerBaseUrl}/api/users/signup');
    final Map<String, dynamic> requestBody = {
      'email': email,
      'password': password,
      'username': username,
    };
    print(requestBody);
    print(
        'signUp loooooooooooooooooooooooooooooooooooooooooooooooooooooooooo ${url}');

    try {
      final response = await http
          .post(
            url,
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(Duration(seconds: 10));

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 202) {
        // User created successfully
        return responseBody;
      } else if (response.statusCode == 400) {
        print(responseBody);
        throw BadRequestException();
      } else if (response.statusCode == 409) {
        throw ConflictException();
      } else if (response.statusCode == 500) {
        throw InternalServerErrorException();
      } else {
        throw Exception('Failed to create user');
      }
    } on TimeoutException {
      throw TimeoutException('The connection has timed out. Please try again.');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> login(
      String emailOrUsername, String password) async {
    print(
        'login loooooooooooooooooooooooooooooooooooooooooooooooooooooooooo ${Constants.webServerBaseUrl}');

    final Uri url = Uri.parse('${Constants.webServerBaseUrl}/api/users/login');
    final Map<String, dynamic> requestBody = {
      'email_or_username': emailOrUsername,
      'password': password,
    };
    print(url);
    try {
      final response = await http
          .post(
            url,
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(Duration(seconds: 5));

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // User logged in successfully, get username from response data
        final String token = responseBody['token'];
        await AuthApiService.cacheToken(token);
        // Return response data
        return responseBody;
      } else if (response.statusCode == 400) {
        throw BadRequestException(message: responseBody['message']);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException(message: responseBody['message']);
      } else if (response.statusCode == 403) {
        throw ForbiddenException(message: responseBody['message']);
      } else if (response.statusCode == 404) {
        throw NotFoundException(message: responseBody['message']);
      } else if (response.statusCode == 409) {
        throw ConflictException(message: responseBody['message']);
      } else if (response.statusCode == 500) {
        throw InternalServerErrorException(message: responseBody['message']);
      } else {
        throw Exception('Failed to login');
      }
    } on TimeoutException {
      throw TimeoutException('The connection has timed out. Please try again.');
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> logout() async {
    try {
      // Get the cached token
      String? token = await AuthApiService.getAuthToken();

      // Send the logout request with the token in the header
      final Uri url =
          Uri.parse('${Constants.webServerBaseUrl}/api/users/logout');
      final response = await http.post(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      final responseBody = jsonDecode(response.body);
      // Check the response status code
      if (response.statusCode == 200) {
        // Successfully logged out, clear the cached token
        await AuthApiService.clearToken();
        UserCredentials().clearUserCredentials();
        // Update MQTT client state to LOGGED_OUT
      } else if (response.statusCode == 400) {
        throw BadRequestException();
      } else if (response.statusCode == 404) {
        throw NotFoundException();
      } else if (response.statusCode == 500) {
        throw InternalServerErrorException();
      } else {
        throw Exception('Failed to logout');
      }
    } on TimeoutException {
      throw TimeoutException('The connection has timed out. Please try again.');
    } catch (e) {
      rethrow;
    }
  }

  static Future<User> getUserInfo() async {
        try {
    String? token = await AuthApiService.getAuthToken();
    final Uri url = Uri.parse('$webServerBaseUrl/api/users/');
    final response = await http.get(
      url,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    print('getUserInfo $token');
    if (response.statusCode == 200) {
      final Map<String, dynamic> userDetails = jsonDecode(response.body);
      return User.fromJson(userDetails);
    } else if (response.statusCode == 404) {
      throw Exception('Not Found - User not found');
    } else if (response.statusCode == 500) {
      throw Exception('Internal Server Error');
    } else {
      throw Exception('Failed to fetch user info');
}
    } on TimeoutException {
      throw TimeoutException('The connection has timed out. Please try again.');
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateUserInfo(
      {required String username, required String email}) async {
    String? token = await AuthApiService.getAuthToken();
    final Uri url = Uri.parse('$webServerBaseUrl/api/users');
    final Map<String, String> body = {
      'username': username,
      'email': email,
    };

    final response = await http.put(
      url,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      // User information updated successfully
    } else if (response.statusCode == 400) {
      throw Exception('Bad Request');
    } else if (response.statusCode == 404) {
      throw Exception('Not Found - User not found');
    } else if (response.statusCode == 409) {
      throw Exception(
          'Conflict - The username or email is already taken or identical to the current one');
    } else if (response.statusCode == 500) {
      throw Exception('Internal Server Error');
    } else {
      throw Exception('Failed to update user info');
    }
  }

  static Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    String? token = await AuthApiService.getAuthToken();
    final Uri url = Uri.parse('$webServerBaseUrl/api/users/password');
    final Map<String, String> body = {
      'old_password': oldPassword,
      'new_password': newPassword,
    };

    final response = await http.put(
      url,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      // Password updated successfully
    } else if (response.statusCode == 400) {
      throw Exception(
          'Bad Request - No password provided or new password is identical to the current one');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Incorrect old password');
    } else if (response.statusCode == 404) {
      throw Exception('Not Found - User not found');
    } else if (response.statusCode == 500) {
      throw Exception('Internal Server Error');
    } else {
      throw Exception('Failed to update password');
    }
  }

  static Future<PaginatedResponse<Mission>> getCurrentMissions({
    int? pageNumber,
    int? pageSize,
    List<MissionStatus>? statuses,
    String? name,
  }) async {
    String? token = await AuthApiService.getAuthToken();

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

    try {
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
      );

      final responseBody = jsonDecode(response.body);
      print('mission responseBody: $responseBody');

      if (response.statusCode == 200) {
        final paginatedResponse = PaginatedResponse<Mission>.fromJson(
            responseBody, (json) => Mission.fromJson(json));
        return paginatedResponse;
      } else if (response.statusCode == 400) {
        throw BadRequestException();
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 403) {
        throw ForbiddenException();
      } else if (response.statusCode == 404) {
        throw NotFoundException();
      } else if (response.statusCode == 500) {
        throw InternalServerErrorException();
      } else {
        throw Exception(
            'Unexpected response from server: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get missions: $e');
    }
  }

  // _________________________________________________________
  static Future<int> getCurrentMissionsCount({
    List<MissionStatus>? statuses,
  }) async {
    final String webServerBaseUrl = Constants.webServerBaseUrl;

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

    try {
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
      );

      final responseBody = jsonDecode(response.body);
      print('mission responseBody: $responseBody');

      if (response.statusCode == 200) {
        final int curMissionsCount = responseBody['cur_missions_count'] ?? 0;
        return curMissionsCount;
      } else if (response.statusCode == 400) {
        throw BadRequestException();
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 403) {
        throw ForbiddenException();
      } else if (response.statusCode == 404) {
        throw NotFoundException();
      } else if (response.statusCode == 500) {
        throw InternalServerErrorException();
      } else {
        throw Exception(
            'Unexpected response from server: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get missions count: $e');
    }
  }
}
