import 'dart:convert';
import 'package:flutter_3/utils/enums.dart';
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
    int? pageNumber,
    int? pageSize,
    List<MissionStatus>? statuses,
  }) async {
    const String baseUrl = Constants.baseUrl;

    // Convert enums to their corresponding integer values

    final List<int>? _missionStatusValues =
        statuses?.map((s) => missionStatusValues[s]!).toList();

    print('_missionStatusValuesfrom getAllMissions: $_missionStatusValues');

    // Convert status values to strings
    final List<String> statusStrings =
        _missionStatusValues?.map((s) => s.toString()).toList() ?? [];

    print('statusStrings from getAllMissions: $statusStrings');
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

    print('queryParameters : $queryParameters');

// Convert query parameters to a list of key-value pairs
    final List<String> queryString =
        queryParameters.entries.map((e) => '${e.key}=${e.value}').toList();

// Join query parameters with '&' to form the final query string
    final String queryStringJoined = queryString.join('&');

    final Uri url = Uri.parse('$baseUrl/api/missions/all?$queryStringJoined');

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
        // Parse the response body into a list of User objects
        final List<dynamic> missionsJson = responseBody;
        final List<Mission> missions =
            missionsJson.map((json) => Mission.fromJson(json)).toList();
        return missions;
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

  static Future<void> updateMissionStatus(
      String missionId, String command) async {
    try {
      String? token = await AuthApiService.getAuthToken();
      const String baseUrl = Constants.baseUrl;
      final Uri url = Uri.parse('$baseUrl/api/missions/$missionId/$command');
      print('url $url');

      final response = await http.put(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        // Mission status updated successfully
        print('Mission status is updated successfully.');
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
        // Handle unexpected response
        throw Exception(
            'Unexpected response from server: ${response.statusCode}');
      }
    } catch (e) {
      // Handle errors
      throw Exception('Failed to update mission status: $e');
    }
  }

  static Future<Map<String, dynamic>> getMissionDetails(
      String missionId) async {
    try {
      String? token = await AuthApiService.getAuthToken();
      const String baseUrl = Constants.baseUrl;
      final Uri url = Uri.parse('$baseUrl/api/missions/$missionId');

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      print(url);
      print(token);
      if (response.statusCode == 200) {
        print('getMissionDetails ${response.body}');
        return json.decode(response.body);
      } else if (response.statusCode == 400) {
        throw BadRequestException();
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 404) {
        throw NotFoundException();
      } else if (response.statusCode == 500) {
        throw InternalServerErrorException();
      } else {
        // Handle unexpected response
        throw Exception(
            'Unexpected response from server: ${response.statusCode}');
      }
    } catch (e) {
      // Handle errors
      throw Exception('Failed to retrieve user info: $e');
    }
  }
}
