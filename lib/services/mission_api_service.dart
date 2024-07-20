import 'package:flutter/material.dart';
import 'package:flutter_3/models/paginated_response.dart';
import 'package:flutter_3/utils/app_colors.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/utils/http_utils.dart';
import 'package:flutter_3/utils/snackbar_utils.dart';
import 'package:flutter_3/utils/exceptions.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/services/auth_api_service.dart';

class MissionApiService {
  static Future<String?> createMission({
    required BuildContext context,
    required String name,
    required List<String> deviceIds,
    required List<String> userIds,
    required String brokerId,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'name': name,
        'device_ids': deviceIds,
        'user_ids': userIds,
        'broker_id': brokerId,
      };
      final response = await HttpUtils.makeRequest(
          context: context,
          endpoint: '/api/missions/',
          method: 'POST',
          body: body);

      if (response.isNotEmpty) {
        final String message =
            response['message'] ?? 'Mission created successfully';
        SnackbarUtils.showSnackBar(context, message,
            backgroundColor: successColor);

        // Extract relevant data from the response
        String missionId = response['mission_id'] ?? '';
        // Print the mission ID
        print('Mission created successfully with ID: $missionId');
        return missionId;
      } else {
        throw Exception('Failed to create mission');
      }
    } on Exception catch (e) {
      print('Error during createMission: $e');
      rethrow;
    }
  }

  static Future<void> updateMission({
    required BuildContext context,
    required String missionId,
    String? name,
    List<String>? deviceIds,
    List<String>? userIds,
    String? brokerId,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (deviceIds != null) body['device_ids'] = deviceIds;
      if (userIds != null) body['user_ids'] = userIds;
      if (brokerId != null) body['broker_id'] = brokerId;

      final response = await HttpUtils.makeRequest(
          context: context,
          endpoint: '/api/missions/$missionId',
          method: 'PUT',
          body: body);

      if (response.isNotEmpty) {
        final String message =
            response['message'] ?? 'mission updated successfully';
        SnackbarUtils.showSnackBar(context, message,
            backgroundColor: successColor);
      } else {
        throw Exception('Failed to update mission $missionId');
      }
    } on Exception catch (e) {
      print('Error during updateMission: $e');
      rethrow;
    }
  }

  static Future<PaginatedResponse<Mission>> getAllMissions({
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

// Convert query parameters to a list of key-value pairs
      final List<String> queryString =
          queryParameters.entries.map((e) => '${e.key}=${e.value}').toList();

// Join query parameters with '&' to form the final query string
      final String queryStringJoined = queryString.join('&');

      final String? token = await AuthApiService.getAuthToken();
      if (token == null) {
        throw UnauthorizedException();
      }
      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/missions/all?$queryStringJoined',
        method: 'GET',
      );

      if (response.isNotEmpty) {
        final paginatedResponse = PaginatedResponse<Mission>.fromJson(
            response, (json) => Mission.fromJson(json));
        return paginatedResponse;
      } else {
        throw Exception('Failed to get mission list.');
      }
    } on Exception catch (e) {
      print('Error during getAllMissions: $e');
      rethrow;
    }
  }

  static Future<void> updateMissionStatus(
      {required BuildContext context,
      required String missionId,
      required String command}) async {
    try {
      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/missions/$missionId/$command',
        method: 'PUT',
      );

      if (response.isNotEmpty) {
        final String message =
            response['message'] ?? 'Mission status updated successfully';
        SnackbarUtils.showSnackBar(context, message,
            backgroundColor: successColor);
      } else {
        throw Exception('Failed to update mission status.');
      }
    } on Exception catch (e) {
      print('Error during updateMissionStatus: $e');
      rethrow;
    }
  }

  static Future<Mission> getMissionDetails(
      {required BuildContext context, required String missionId}) async {
    try {
      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/missions/$missionId',
        method: 'GET',
      );

      if (response.isNotEmpty) {
        return Mission.fromJson(response);
      } else {
        throw Exception('Failed to get mission details.');
      }
    } on Exception catch (e) {
      print('Error during getMissionDetails: $e');
      rethrow;
    }
  }
}
