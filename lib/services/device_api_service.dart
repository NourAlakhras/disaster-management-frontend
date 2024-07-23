import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/paginated_response.dart';
import 'package:flutter_3/utils/app_colors.dart';
import 'package:flutter_3/utils/http_utils.dart';
import 'package:flutter_3/utils/snackbar_utils.dart';
import 'package:flutter_3/utils/enums.dart';

class DeviceApiService {
  static Future<PaginatedResponse<Device>> getAllDevices({
    required BuildContext context,
    int? pageNumber,
    int? pageSize,
    List<DeviceStatus>? statuses,
    List<DeviceType>? types,
    String? missionId,
    String? brokerId,
    String? name,
  }) async {
    try {
      // Convert enums to their corresponding integer values
      final List<int>? typeValues =
          types?.map((t) => deviceTypeValues[t]!).toList();

      final List<int>? statusValues =
          statuses?.map((s) => deviceStatusValues[s]!).toList();

      // Build query parameters
      Map<String, dynamic> queryParameters = {
        'page-number': pageNumber ?? 1,
        'page-size': pageSize ?? 6,
      };

      // Add status query parameters
      if (statusValues != null && statusValues.isNotEmpty) {
        // Concatenate status values with the same key
        queryParameters['status'] = statusValues.join('&status=');
      }

      // Add type query parameters
      if (typeValues != null && typeValues.isNotEmpty) {
        // Concatenate type values with the same key
        queryParameters['type'] = typeValues.join('&type=');
      }

      if (missionId != null) {
        queryParameters['mission'] = missionId;
      }
      if (brokerId != null) {
        queryParameters['broker'] = brokerId;
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

      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/devices/all?$queryStringJoined',
        method: 'GET',
      );

      if (response.isNotEmpty) {
        final paginatedResponse = PaginatedResponse<Device>.fromJson(
            response, (json) => Device.fromJson(json));
        return paginatedResponse;
      } else {
        throw Exception('Failed to get devices list.');
      }
    } on Exception catch (e) {
      print('Error during getAllDevices: $e');
      rethrow;
    }
  }

  static Future<Device> getDeviceDetails(
      {required BuildContext context, required String deviceId}) async {
    try {
      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/devices/$deviceId',
        method: 'GET',
      );

      if (response.isNotEmpty) {
        return Device.fromJson(response);
      } else {
        throw Exception('Failed to get device details.');
      }
    } on Exception catch (e) {
      print('Error during getDeviceDetails: $e');
      rethrow;
    }
  }

  static Future<void> updateDevice({
    required BuildContext context,
    required String deviceId,
    String? name,
    String? oldPassword,
    String? newPassword,
  }) async {
    try {
      // Dynamically build the request body
      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (oldPassword != null) body['old_password'] = oldPassword;
      if (newPassword != null) body['new_password'] = newPassword;

      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/devices/$deviceId',
        method: 'PUT',
        body: body,
      );

      if (response.isNotEmpty) {
        final String message =
            response['message'] ?? 'Device information updated successfully';
        SnackbarUtils.showSnackBar(context, message,
            backgroundColor: successColor);
      } else {
        throw Exception('Failed to update device information.');
      }
    } on Exception catch (e) {
      print('Error during updateDevice: $e');
      rethrow;
    }
  }

  static Future<void> verifyPassword({
    required BuildContext context,
    required String deviceId,
    required String password,
  }) async {
    try {
      // Dynamically build the request body
      final Map<String, dynamic> body = {};
      body['old_password'] = password;

      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/devices/$deviceId',
        method: 'PUT',
        body: body,
      );

      if (response.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password verified successfully'),
            backgroundColor: successColor,
          ),
        );
      } else {
        throw Exception('Failed to verify password.');
      }
    } on Exception catch (e) {
      print('Error during verifyPassword: $e');
      rethrow;
    }
  }

  static Future<Device> deleteDevice(
      {required BuildContext context, required String deviceId}) async {
    try {
      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/devices/$deviceId',
        method: 'DELETE',
      );

      if (response.isNotEmpty) {
        final String message =
            response['message'] ?? 'Device deleted successfully';
        SnackbarUtils.showSnackBar(context, message,
            backgroundColor: successColor);

        return Device.fromJson(response);
      } else {
        throw Exception('Failed to delete device.');
      }
    } on Exception catch (e) {
      print('Error during deleteDevice: $e');
      rethrow;
    }
  }

  static Future<void> updateDeviceState({
    required BuildContext context,
    required String deviceId,
    required String newState,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'state': newState,
      };
      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/devices/$deviceId/state',
        method: 'PUT',
        body: body,
      );

      if (response.isNotEmpty) {
        final String message =
            response['message'] ?? 'Device state updated successfully';
        SnackbarUtils.showSnackBar(context, message,
            backgroundColor: successColor);
      } else {
        throw Exception('Failed to update device information.');
      }
    } on Exception catch (e) {
      print('Error during updateDeviceState: $e');
      rethrow;
    }
  }
}
