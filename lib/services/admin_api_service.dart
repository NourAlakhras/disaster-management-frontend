import 'package:flutter/material.dart';
import 'package:flutter_3/models/paginated_response.dart';
import 'package:flutter_3/utils/app_colors.dart';
import 'package:flutter_3/utils/http_utils.dart';
import 'package:flutter_3/utils/snackbar_utils.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/utils/enums.dart';

class AdminApiService {
  static Future<PaginatedResponse<User>> getAllUsers({
    required BuildContext context,
    int? pageNumber,
    int? pageSize,
    List<UserStatus>? statuses,
    List<UserType>? types,
    String? missionId,
    String? username,
  }) async {
    try {
      // Convert enums to their corresponding integer values
      final List<int>? _typeValues =
          types?.map((t) => userTypeValues[t]!).toList();

      final List<int>? _statusValues =
          statuses?.map((s) => userStatusValues[s]!).toList();

      // Build query parameters
      Map<String, dynamic> queryParameters = {
        'page-number': pageNumber ?? 1,
        'page-size': pageSize ?? 6,
      };

      // Add status query parameters
      if (_statusValues != null && _statusValues.isNotEmpty) {
        // Concatenate status values with the same key
        queryParameters['status'] = _statusValues.join('&status=');
      }

      // Add type query parameters
      if (_typeValues != null && _typeValues.isNotEmpty) {
        // Concatenate type values with the same key
        queryParameters['type'] = _typeValues.join('&type=');
      }

      if (missionId != null) {
        queryParameters['mission'] = missionId;
      }
      if (username != "" && username != null && username.isNotEmpty) {
        queryParameters['username'] = username;
      }

// Convert query parameters to a list of key-value pairs
      final List<String> queryString =
          queryParameters.entries.map((e) => '${e.key}=${e.value}').toList();

// Join query parameters with '&' to form the final query string
      final String queryStringJoined = queryString.join('&');

      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/users/all?$queryStringJoined',
        method: 'GET',
      );

      if (response.isNotEmpty) {
        final paginatedResponse = PaginatedResponse<User>.fromJson(
            response, (json) => User.fromJson(json));
        return paginatedResponse;
      } else {
        throw Exception('Failed to get users list.');
      }
    } on Exception catch (e) {
      print('Error during getAllUsers: $e');
      rethrow;
    }
  }

  static Future<void> approveUser(
      {required BuildContext context,
      required String userId,
      required bool isAdmin}) async {
    try {
      final response = await HttpUtils.makeRequest(
          context: context,
          endpoint: '/api/users/$userId/approval',
          method: 'PUT',
          body: {
            'approved': true,
            'type': isAdmin
                ? userTypeValues[UserType.ADMIN]
                : userTypeValues[UserType.REGULAR],
          });

      if (response.isNotEmpty) {
        final String message =
            response['message'] ?? 'User approved successfully';
        SnackbarUtils.showSnackBar(context, message,
            backgroundColor: successColor);
      } else {
        throw Exception('Failed to approve user $userId');
      }
    } on Exception catch (e) {
      print('Error during approveUser: $e');
      rethrow;
    }
  }

  static Future<void> rejectUser(
      {required BuildContext context, required String userId}) async {
    try {
      final response = await HttpUtils.makeRequest(
          context: context,
          endpoint: '/api/users/$userId/approval',
          method: 'PUT',
          body: {
            'approved': false,
          });

      if (response.isNotEmpty) {
        final String message =
            response['message'] ?? 'User rejected successfully';
        SnackbarUtils.showSnackBar(context, message,
            backgroundColor: successColor);
      } else {
        throw Exception('Failed to reject user .');
      }
    } on Exception catch (e) {
      print('Error during rejectUser: $e');
      rethrow;
    }
  }

  static Future<void> deleteUser(
      {required BuildContext context, required String userId}) async {
    try {
      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/users/$userId',
        method: 'DELETE',
      );
      if (response.isNotEmpty) {
        final String message =
            response['message'] ?? 'User account is deleted successfully';
        SnackbarUtils.showSnackBar(context, message,
            backgroundColor: successColor);
      } else {
        throw Exception('Failed to delete user account.');
      }
    } on Exception catch (e) {
      print('Error during deleteUser: $e');
      rethrow;
    }
  }

  static Future<User> getUserDetails(
      {required BuildContext context, required String userId}) async {
    try {
      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/users/$userId',
        method: 'GET',
      );

      if (response.isNotEmpty) {
        return User.fromJson(response);
      } else {
        throw Exception('Failed to get user details.');
      }
    } on Exception catch (e) {
      print('Error during getUserDetails: $e');
      rethrow;
    }
  }

  static Future<int> getUserCount(
      {required BuildContext context,
      List<int>? status,
      List<int>? type}) async {
    try {
      // Construct query parameters based on provided filters
      Map<String, dynamic> queryParameters = {};
      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status.join(',');
      }
      if (type != null && type.isNotEmpty) {
        queryParameters['type'] = type.join(',');
      }

      // Construct the query string from parameters
      final String queryString = queryParameters.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/users/count?$queryString',
        method: 'GET',
      );

      if (response.isNotEmpty) {
        final int count = response['count'];
        return count;
      } else {
        throw Exception('Failed to get users count.');
      }
    } on Exception catch (e) {
      print('Error during getUserCount: $e');
      rethrow;
    }
  }

  static Future<int> getDeviceCount(
      {required BuildContext context,
      List<int>? status,
      List<int>? type}) async {
    try {
      // Construct query parameters based on provided filters
      List<String> queryParameters = [];

      if (status != null && status.isNotEmpty) {
        queryParameters.addAll(status.map((s) => 'status=$s'));
      }
      if (type != null && type.isNotEmpty) {
        queryParameters.addAll(type.map((t) => 'type=$t'));
      }

      // Join query parameters with '&' to form the final query string
      final String queryStringJoined = queryParameters.join('&');
      print('queryStringJoined $queryStringJoined');
      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/devices/count?$queryStringJoined',
        method: 'GET',
      );

      if (response.isNotEmpty) {
        print('response $response');
        final int count = response['count'];
        return count;
      } else {
        throw Exception('Failed to get devices count.');
      }
    } on Exception catch (e) {
      print('Error during getDeviceCount: $e');
      rethrow;
    }
  }

  static Future<int> getMissionCount(
      {required BuildContext context, List<int>? status}) async {
    try {
      // Construct query parameters based on provided filters
      Map<String, dynamic> queryParameters = {};
      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status.join(',');
      }

      // Construct the query string from parameters
      final String queryString = queryParameters.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/missions/count?$queryString',
        method: 'GET',
      );

      if (response.isNotEmpty) {
        final int count = response['count'];
        return count;
      } else {
        throw Exception('Failed to get devices count.');
      }
    } on Exception catch (e) {
      print('Error during getDeviceCount: $e');
      rethrow;
    }
  }

  static Future<void> updateUser({
    required BuildContext context,
    required String user_id,
    String? email,
    UserType? type,
  }) async {
    final Map<String, dynamic> body = {};

    if (email != null) {
      body['email'] = email;
    }

    if (type != null) {
      body['type'] = userTypeValues[type];
    }

    try {
      final response = await HttpUtils.makeRequest(
        context: context,
        endpoint: '/api/users/$user_id',
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
      print('Error during updateUser: $e');
      rethrow;
    }
  }
}
