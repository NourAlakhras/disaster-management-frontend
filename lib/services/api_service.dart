import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.100.9:5000';

  static Future<Map<String, dynamic>> signUp(
      String email, String username, String password) async {
    final Uri url = Uri.parse('$baseUrl/user/signup');
    print(url);
    final Map<String, String> body = {
      'email': email,
      'username': username,
      'password': password,
    };

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      // User created successfully, set user credentials and establish MQTT connection
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final String token = responseData['token'];
      await _cacheToken(token);

      // Return response data
      return responseData;
    } else if (response.statusCode == 409) {
      print('Email or Username is already taken');
      throw Exception('Email or Username is already taken');
    } else if (response.statusCode == 400) {
      print('Bad Request');
      throw Exception('Bad Request');
    } else if (response.statusCode == 500) {
      print('Internal Server Error');
      throw Exception('Internal Server Error');
    } else {
      print('Failed to sign up');
      throw Exception('Failed to sign up');
    }
  }

  static Future<Map<String, dynamic>> login(
      String emailOrUsername, String password) async {
    final Uri url = Uri.parse('$baseUrl/user/login');
    final Map<String, String> body = {
      'email_or_username': emailOrUsername,
      'password': password,
    };

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      // User logged in successfully, get username from response data
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final String token = responseData['token'];
      await _cacheToken(token);

      // Return response data
      return responseData;
    } else if (response.statusCode == 400) {
      // Bad Request
      throw Exception('Bad Request');
    } else if (response.statusCode == 401) {
      // Unauthorized - Invalid email or password
      throw Exception('Unauthorized - Invalid email or password');
    } else if (response.statusCode == 500) {
      print('Internal Server Error');
      throw Exception('Internal Server Error');
    } else {
      // Internal Server Error or other unexpected error
      throw Exception('Failed to login');
    }
  }

  static Future<void> logout() async {
    // Get the cached token
    String? token = await getAuthToken();

    // Send the logout request with the token in the header
    final Uri url = Uri.parse('$baseUrl/user/logout');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    // Check the response status code
    if (response.statusCode == 200) {
      // Successfully logged out, clear the cached token
      await _clearToken();
      UserCredentials().clearUserCredentials();
      // Update MQTT client state to LOGGED_OUT
    } else if (response.statusCode == 400) {
      // Invalid token
      throw Exception('Bad Request - Invalid token');
    } else if (response.statusCode == 404) {
      // User not found
      throw Exception('Not Found - User not found');
    } else if (response.statusCode == 500) {
      print('Internal Server Error');
      throw Exception('Internal Server Error');
    } else {
      // Internal server error or other unexpected error
      throw Exception('Failed to logout');
    }
  }

  static Future<Map<String, dynamic>> getUserInfo() async {
    String? token = await getAuthToken();
    final Uri url = Uri.parse('$baseUrl/user');
    final response = await http.get(
      url,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

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
    String? token = await getAuthToken();
    final Uri url = Uri.parse('$baseUrl/user');
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
    String? token = await getAuthToken();
    final Uri url = Uri.parse('$baseUrl/user/password');
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
    String? token = await getAuthToken();
    final Uri url = Uri.parse('$baseUrl/user/cur_missions');
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

  static Future<Map<String, dynamic>> getMissionInfo(String missionId) async {
    String? token = await getAuthToken();
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

  static Future<void> _cacheToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> _clearToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
