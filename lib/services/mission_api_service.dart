import 'dart:convert';
import 'package:flutter_3/models/paginated_response.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_3/utils/constants.dart';
import 'package:flutter_3/utils/exceptions.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/services/auth_api_service.dart';

class MissionApiService {
  static Future<String?> createMission({
    required String name,
    required List<String> deviceIds,
    required List<String> userIds,
    required String brokerId,
  }) async {
    const String baseUrl = Constants.baseUrl;
    final Uri url = Uri.parse('$baseUrl/api/missions/');

    final Map<String, dynamic> requestBody = {
      'name': name,
      'device_ids': deviceIds,
      'user_ids': userIds,
      'broker_id': brokerId,
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
      print('create mission requestBody: $requestBody');
      if (response.statusCode == 201) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        // Extract relevant data from the response
        String missionId = responseBody['mission_id'] ?? '';
        // Print the mission ID
        print('Mission created successfully with ID: $missionId');
        return missionId;
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
      throw Exception('Failed to create mission: $e');
    }
  }


  static Future<void> updateMission({
    required String missionId,
    String? name,
    List<String>? deviceIds,
    List<String>? userIds,
    String? brokerId,
  }) async {
    const String baseUrl = Constants.baseUrl;
    final Uri url = Uri.parse('$baseUrl/api/missions/$missionId');

    final Map<String, dynamic> requestBody = {};
    if (name != null) requestBody['name'] = name;
    if (deviceIds != null) requestBody['device_ids'] = deviceIds;
    if (userIds != null) requestBody['user_ids'] = userIds;
    if (brokerId != null) requestBody['broker_id'] = brokerId;

    print('updateMission url $url');
    print('updateMission requestBody $requestBody');
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
      print('update mission requestBody: $requestBody');

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


  static Future<PaginatedResponse<Mission>> getAllMissions({
    int? pageNumber,
    int? pageSize,
    List<MissionStatus>? statuses,
    String? name,
  }) async {
    const String baseUrl = Constants.baseUrl;

    // Convert enums to their corresponding integer values
    final List<int>? _missionStatusValues =
        statuses?.map((s) => missionStatusValues[s]!).toList();

    print('statuses from getAllMissions: $statuses');
    print('_missionStatusValues from getAllMissions: $_missionStatusValues');

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

    if (name != "" && name != null && name.isNotEmpty) {
      queryParameters['name'] = name;
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

  static Future<Mission> getMissionDetails(String missionId) async {
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

      if (response.statusCode == 200) {
        print('getMissionDetails response.body ${response.body}');
        final Map<String, dynamic> missionDetails = jsonDecode(response.body);
        return Mission.fromJson(missionDetails);
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
      throw Exception('Failed to retrieve mission details: $e');
    }
  }
}
