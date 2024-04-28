import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_3/utils/constants.dart';
import 'package:flutter_3/utils/exceptions.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/services/auth_api_service.dart';

class MissionApiService {
  static Future<String> createMission({
    required String name,
    required List<String> deviceIds,
    required List<String> userIds,
  }) async {
    const String baseUrl = Constants.baseUrl;
    final Uri url = Uri.parse('$baseUrl/api/missions');

    final Map<String, dynamic> requestBody = {
      'name': name,
      'device_ids': deviceIds,
      'user_ids': userIds,
    };

    try {
      String? token = await AuthApiService.getAuthToken();

      final response = await http.post(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 308) {
        // Handle redirection
        String newUrl = response.headers['location']!;
        // Send another request to the new URL
        final redirectedResponse = await http.post(
          Uri.parse(newUrl),
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(requestBody),
        );

        // Process redirected response
        if (redirectedResponse.statusCode == 201) {
          final Map<String, dynamic> responseBody =
              jsonDecode(redirectedResponse.body);
          // Extract relevant data from the response
          String missionId = responseBody['mission_id'] ?? '';
          // Print the mission ID
          print('Mission created successfully with ID: $missionId');
          return missionId;
        }
      } else if (response.statusCode == 400) {
        throw BadRequestException();
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 403) {
        throw ForbiddenException();
      } else if (response.statusCode == 404) {
        throw NotFoundException();
      } else if (response.statusCode == 409) {
        throw ConflictException();
      } else if (response.statusCode == 500) {
        throw InternalServerErrorException();
      } else {
        throw Exception(
            'Unexpected response from server: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to create mission: $e');
      throw Exception(
          'Failed to create mission: $e'); // Throw an exception to ensure a non-null return value
    }
        return '';
  }

  static Future<Mission> getMissionById(String missionId) async {
    const String baseUrl = Constants.baseUrl;
    final Uri url = Uri.parse('$baseUrl/api/missions/$missionId');

    try {
      String? token = await AuthApiService.getAuthToken();

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        return Mission.fromJson(responseBody);
      } else if (response.statusCode == 404) {
        throw NotFoundException();
      } else if (response.statusCode == 500) {
        throw InternalServerErrorException();
      } else {
        throw Exception(
            'Unexpected response from server: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get mission: $e');
    }
  }

  static Future<void> updateMission(
    String missionId, {
    required String name,
    required List<String> deviceIds,
    required List<String> userIds,
  }) async {
    const String baseUrl = Constants.baseUrl;
    final Uri url = Uri.parse('$baseUrl/api/missions/$missionId');

    final Map<String, dynamic> requestBody = {
      'name': name,
      'device_ids': deviceIds,
      'user_ids': userIds,
    };

    try {
      String? token = await AuthApiService.getAuthToken();

      final response = await http.put(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        // Mission updated successfully, no need to return anything
      } else if (response.statusCode == 400) {
        throw BadRequestException();
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 403) {
        throw ForbiddenException();
      } else if (response.statusCode == 404) {
        throw NotFoundException();
      } else if (response.statusCode == 409) {
        throw ConflictException();
      } else if (response.statusCode == 500) {
        throw InternalServerErrorException();
      } else {
        throw Exception(
            'Unexpected response from server: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update mission: $e');
    }
  }

  static Future<List<Mission>> getAllMissions({
    required int pageNumber,
    required int pageSize,
    int? status,
  }) async {
    const String baseUrl = Constants.baseUrl;
    final Uri url = Uri.parse(
        '$baseUrl/api/missions/all?page-number=$pageNumber&page-size=$pageSize${status != null ? '&status=$status' : ''}');

    try {
      String? token = await AuthApiService.getAuthToken();

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseBody = jsonDecode(response.body);
        return responseBody.map((json) => Mission.fromJson(json)).toList();
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
}
