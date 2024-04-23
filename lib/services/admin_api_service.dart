import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_3/utils/constants.dart';
import 'package:flutter_3/utils/exceptions.dart';
import 'package:flutter_3/models/user.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/services/auth_api_service.dart';

class AdminApiService {
  static Future<dynamic> getAllUsers({
    String? userType,
    required int pageNumber,
    required int pageSize,
    int? status,
    int? type,
    String? missionId,
  }) async {
    const String baseUrl = Constants.baseUrl;
    final String queryString = _buildQueryString(
      pageNumber: pageNumber,
      pageSize: pageSize,
      status: status,
      type: type,
      missionId: missionId,
    );

    final Uri url = Uri.parse('$baseUrl/api/users/all?$queryString');

    // Print out the generated URL
    print('URL: $url');

    try {
      String? token = await AuthApiService.getAuthToken();
      print(token);

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      final responseBody = jsonDecode(response.body);
      print(token);
      print("eee");
      print(responseBody);

      if (response.statusCode == 200) {
        // Parse the response body into a list of User objects
        final List<dynamic> usersJson = responseBody;
        final List<User> users =
            usersJson.map((json) => User.fromJson(json)).toList();
        return users;
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
        // Handle unexpected response
        throw Exception(
            'Unexpected response from server: ${response.statusCode}');
      }
    } on FormatException catch (e) {
      // Handle unexpected response format (e.g., HTML instead of JSON)
      throw Exception('Unexpected response format: $e');
    } catch (e) {
      // Handle other errors
      throw Exception('Failed to fetch users: $e');
    }
  }

  static String _buildQueryString({
    required int pageNumber,
    required int pageSize,
    int? status,
    int? type,
    String? missionId,
  }) {
    final Map<String, dynamic> queryParameters = {
      'page-number': pageNumber.toString(),
      'page-size': pageSize.toString(),
    };

    if (status != null) {
      queryParameters['status'] = status.toString();
    }
    if (type != null) {
      queryParameters['type'] = type.toString();
    }
    if (missionId != null) {
      queryParameters['mission'] = missionId;
    }

    return Uri(queryParameters: queryParameters).query;
  }

  static Future<void> approveUser(String userId, bool isAdmin) async {
    try {
      print('hi $isAdmin');
      int type = isAdmin ? 2 : 1;
      print(type);
      String? token = await AuthApiService.getAuthToken();
      const String baseUrl = Constants.baseUrl;
      final Uri url = Uri.parse('$baseUrl/api/users/$userId/approval');

      final response = await http.put(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'approved': true,
          'type': isAdmin
              ? userTypeValues[UserType.ADMIN]
              : userTypeValues[UserType.REGULAR],
        }),
      );
      print(url);
      print(token);
      if (response.statusCode == 200) {
        // User account status updated successfully
        print('User account status updated successfully.');
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
      throw Exception('Failed to approve user: $e');
    }
  }

  static Future<void> rejectUser(String userId) async {
    try {
      String? token = await AuthApiService.getAuthToken();
      const String baseUrl = Constants.baseUrl;
      final Uri url = Uri.parse('$baseUrl/api/users/$userId/approval');

      final response = await http.put(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'approved': false,
        }),
      );
      print(url);
      print(token);
      if (response.statusCode == 200) {
        // User account status updated successfully
        print('User account status updated successfully.');
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
      throw Exception('Failed to approve user: $e');
    }
  }

  static Future<void> deleteUser(String userId) async {
    try {
      String? token = await AuthApiService.getAuthToken();
      const String baseUrl = Constants.baseUrl;
      final Uri url = Uri.parse('$baseUrl/api/users/$userId');

      final response = await http.delete(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      print(url);
      print(token);
      if (response.statusCode == 200) {
        // User account status updated successfully
        print('User account is deactivated successfully.');
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
      throw Exception('Failed to deactivate user: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      String? token = await AuthApiService.getAuthToken();
      const String baseUrl = Constants.baseUrl;
      final Uri url = Uri.parse('$baseUrl/api/users/$userId');

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
    static Future<int> getUserCount({List<int>? status, List<int>? type}) async {
    try {
      String? token = await AuthApiService.getAuthToken();
      const String baseUrl = Constants.baseUrl;
      final Uri url = Uri.parse('$baseUrl/api/users/count');

      // Construct query parameters based on provided filters
      Map<String, dynamic> queryParameters = {};
      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status.join(',');
      }
      if (type != null && type.isNotEmpty) {
        queryParameters['type'] = type.join(',');
      }

      final response = await http.get(
        url.replace(
            queryParameters:
                queryParameters), // Use replace to include query parameters
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        // Parse the response body to get the count
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final int count = responseBody['count'];
        return count;
      } else if (response.statusCode == 400) {
        throw BadRequestException();
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 403) {
        throw ForbiddenException();
      } else if (response.statusCode == 500) {
        throw InternalServerErrorException();
      } else {
        // Handle unexpected response
        throw Exception(
            'Unexpected response from server: ${response.statusCode}');
      }
    } catch (e) {
      // Handle errors
      throw Exception('Failed to get user count: $e');
    }
  }
  
static Future<int> getDeviceCount(
      {List<int>? status, List<int>? type}) async {
    try {
      String? token = await AuthApiService.getAuthToken();
      const String baseUrl = Constants.baseUrl;
      final Uri url = Uri.parse('$baseUrl/api/devices/count');

      // Construct query parameters based on provided filters
      Map<String, dynamic> queryParameters = {};
      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status.join(',');
      }
      if (type != null && type.isNotEmpty) {
        queryParameters['type'] = type.join(',');
      }

      final response = await http.get(
        url.replace(
            queryParameters:
                queryParameters), // Use replace to include query parameters
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        // Parse the response body to get the count
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final int count = responseBody['count'];
        return count;
      } else if (response.statusCode == 400) {
        throw BadRequestException();
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 403) {
        throw ForbiddenException();
      } else if (response.statusCode == 500) {
        throw InternalServerErrorException();
      } else {
        // Handle unexpected response
        throw Exception(
            'Unexpected response from server: ${response.statusCode}');
      }
    } catch (e) {
      // Handle errors
      throw Exception('Failed to get device count: $e');
    }
  }

  static Future<int> getMissionCount({List<int>? status}) async {
    try {
      String? token = await AuthApiService.getAuthToken();
      const String baseUrl = Constants.baseUrl;
      final Uri url = Uri.parse('$baseUrl/api/missions/count');

      // Construct query parameters based on provided filters
      Map<String, dynamic> queryParameters = {};
      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status.join(',');
      }

      final response = await http.get(
        url.replace(queryParameters: queryParameters),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        // Parse the response body to get the count
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final int count = responseBody['count'];
        return count;
      } else if (response.statusCode == 400) {
        throw BadRequestException();
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else if (response.statusCode == 403) {
        throw ForbiddenException();
      } else if (response.statusCode == 500) {
        throw InternalServerErrorException();
      } else {
        // Handle unexpected response
        throw Exception(
            'Unexpected response from server: ${response.statusCode}');
      }
    } catch (e) {
      // Handle errors
      throw Exception('Failed to get mission count: $e');
    }
  }

}
