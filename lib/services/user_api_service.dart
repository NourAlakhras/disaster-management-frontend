import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/services/auth_api_service.dart';
import 'package:flutter_3/utils/constants.dart';
import 'package:flutter_3/utils/exceptions.dart';
import 'package:flutter_3/models/mission.dart';

class UserApiService {
  static const String baseUrl = Constants.baseUrl;

  static Future<Map<String, dynamic>> signUp(
      String email, String password, String username) async {
    final Uri url = Uri.parse('${Constants.baseUrl}/api/users/signup');
    final Map<String, dynamic> requestBody = {
      'email': email,
      'password': password,
      'username': username,
    };
    print(requestBody);
    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

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
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> login(
      String emailOrUsername, String password) async {
    final Uri url = Uri.parse('${Constants.baseUrl}/api/users/login');
    final Map<String, dynamic> requestBody = {
      'email_or_username': emailOrUsername,
      'password': password,
    };

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // User logged in successfully, get username from response data
        final String token = responseBody['token'];
        await AuthApiService.cacheToken(token);
        // Return response data
        return responseBody;
      } else if (response.statusCode == 400) {
        throw BadRequestException();
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 403) {
        throw ForbiddenException();
      } else if (response.statusCode == 500) {
        throw InternalServerErrorException();
      } else {
        throw Exception('Failed to login');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> logout() async {
    try {
      // Get the cached token
      String? token = await AuthApiService.getAuthToken();

      // Send the logout request with the token in the header
      final Uri url = Uri.parse('${Constants.baseUrl}/api/users/logout');
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
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getUserInfo() async {
    String? token = await AuthApiService.getAuthToken();
    final Uri url = Uri.parse('$baseUrl/api/users');
    final response = await http.get(
      url,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    print('getUserInfo $token');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Not Found - User not found');
    } else if (response.statusCode == 500) {
      throw Exception('Internal Server Error');
    } else {
      throw Exception('Failed to fetch user info');
    }
  }

  static Future<void> updateUserInfo(String username, String email) async {
    String? token = await AuthApiService.getAuthToken();
    final Uri url = Uri.parse('$baseUrl/api/users');
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

  static Future<void> updatePassword(
      String oldPassword, String newPassword) async {
    String? token = await AuthApiService.getAuthToken();
    final Uri url = Uri.parse('$baseUrl/api/users/password');
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

  static Map<String, dynamic> dummyApiResponse = {
    'cur_missions': [
      {"_id": "6055a0ae80e90e08641e22ef", "name": "MissionABC", "status": 1},
      {"_id": "6055a0ae80e90e08641e22f0", "name": "MissionXYZ", "status": 2},
      // Add more missions as needed
    ]
  };

  static Future<List<dynamic>> getCurrentMissions() async {
    String? token = await AuthApiService.getAuthToken();
    final Uri url = Uri.parse('$baseUrl/api/users/cur_missions');
    final response = await http.get(
      url,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      // final Map<String, dynamic> responseData = jsonDecode(response.body);
      final Map<String, dynamic> responseData = dummyApiResponse;
      // Extract missions from the map
      final List<dynamic> missionData = responseData['cur_missions'];
      return missionData; // Return the list of missions
    } else if (response.statusCode == 404) {
      throw Exception('Not Found - User not found');
    } else if (response.statusCode == 500) {
      throw Exception('Internal Server Error');
    } else {
      throw Exception('Failed to fetch current missions');
    }
  }

  // _________________________________________________________

  static Future<List<Mission>> getUserCurrentMissions(String userId) async {
    const String baseUrl = Constants.baseUrl;
    final Uri url = Uri.parse('$baseUrl/api/users/$userId/cur_missions');

    try {
      final String? token = await AuthApiService.getAuthToken();

      final http.Response response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Mission> missions =
            data.map((json) => Mission.fromJson(json)).toList();
        return missions;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 404) {
        return [];
      } else if (response.statusCode == 500) {
        throw InternalServerErrorException();
      } else {
        throw Exception(
            'Unexpected response from server: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to retrieve current missions: $e');
    }
  }

  static Future<Map<String, dynamic>> getMissionInfo(String missionId) async {
    String? token = await AuthApiService.getAuthToken();
    final Uri url = Uri.parse('$baseUrl/mission/$missionId');
    final response = await http.get(
      url,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    Map<String, dynamic> dummyMissionData = {
      '_id': '6055a0ae80e90e08641e22ef',
      'name': 'MissionABC',
      'status': 1,
    };
    return dummyMissionData;

    // if (response.statusCode == 200) {
    //   return jsonDecode(response.body);
    // } else if (response.statusCode == 404) {
    //   throw Exception('Not Found - Mission not found');
    // } else if (response.statusCode == 500) {
    //   throw Exception('Internal Server Error');
    // } else {
    //   throw Exception('Failed to fetch mission information');
    // }
  }
}
