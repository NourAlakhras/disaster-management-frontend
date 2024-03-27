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
