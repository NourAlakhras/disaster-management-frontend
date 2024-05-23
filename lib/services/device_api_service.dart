import 'dart:convert';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/services/auth_api_service.dart';
import 'package:flutter_3/utils/constants.dart';
import 'package:flutter_3/utils/exceptions.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_3/utils/enums.dart';

class DeviceApiService {
  static Future<List<Device>> getAllDevices({
    int? pageNumber,
    int? pageSize,
    List<DeviceStatus>? statuses,
    List<DeviceType>? types,
    String? missionId,
        String? name,
  }) async {
    try {
      print('statuses from getAllDevices: $statuses');

      print('types from getAllDevices: $types');

      const String baseUrl = Constants.baseUrl;

      // Convert enums to their corresponding integer values
      final List<int>? typeValues =
          types?.map((t) => deviceTypeValues[t]!).toList();

      final List<int>? statusValues =
          statuses?.map((s) => deviceStatusValues[s]!).toList();

      print('_statusValues from getAllDevices: $statusValues');

      print('_typeValues from getAllDevices: $typeValues');

      // Convert status values to strings
      final List<String> statusStrings =
          statusValues?.map((s) => s.toString()).toList() ?? [];
      // Convert status values to strings
      final List<String> typeStrings =
          typeValues?.map((s) => s.toString()).toList() ?? [];

      print('statusStrings from getAllDevices: $statusStrings');

      print('typeStrings from getAllDevices: $typeStrings');

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

      if (name != "" && name != null && name.isNotEmpty) {
        queryParameters['name'] = name;
      }
      print('queryParameters : $queryParameters');

      // Convert query parameters to a list of key-value pairs
      final List<String> queryString =
          queryParameters.entries.map((e) => '${e.key}=${e.value}').toList();

      // Join query parameters with '&' to form the final query string
      final String queryStringJoined = queryString.join('&');

      final Uri url = Uri.parse('$baseUrl/api/devices/all?$queryStringJoined');

      // Print out the generated URL
      print('URL: $url');

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
      print('getAllDevices responseBody: $responseBody');

      if (response.statusCode == 200) {
        // Parse the response body into a list of User objects
        final List<dynamic> usersJson = responseBody;
        final List<Device> devices =
            usersJson.map((json) => Device.fromJson(json)).toList();
        return devices;
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
    } catch (e, stackTrace) {
      // Handle other errors
      print('Unexpected error occurred: $e\n$stackTrace');
      throw Exception('Failed to fetch users: $e');
    }
  }
  
  static Future<Device> getDeviceDetails(String deviceId) async {
    try {
      String? token = await AuthApiService.getAuthToken();
      const String baseUrl = Constants.baseUrl;
      final Uri url = Uri.parse('$baseUrl/api/devices/$deviceId');

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        print('getDeviceDetails response.body ${response.body}');
        final Map<String, dynamic> deviceDetails = jsonDecode(response.body);
        return Device.fromJson(deviceDetails);
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
      throw Exception('Failed to retrieve device details: $e');
    }
  }
  
  static Future<void> updateDevice({
    required String deviceId,
    required String name,
    List<String>? missionIds,
  }) async {
    const String baseUrl = Constants.baseUrl;
    final Uri url = Uri.parse('$baseUrl/api/devices/$deviceId');

    final Map<String, dynamic> requestBody = {
      'name': name,
      'missionIds': missionIds,
    };
    print('updateDevice url $url');
    print('updateDevice requestBody $requestBody');
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
        // Device updated successfully, no need to return anything
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
      throw Exception('Failed to update device: $e');
    }
  }

  static Future<Device> deleteDevice(String deviceId) async {
    try {
      String? token = await AuthApiService.getAuthToken();
      const String baseUrl = Constants.baseUrl;
      final Uri url = Uri.parse('$baseUrl/api/devices/$deviceId');

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        print('getDeviceDetails response.body ${response.body}');
        final Map<String, dynamic> deviceDetails = jsonDecode(response.body);
        return Device.fromJson(deviceDetails);
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
      throw Exception('Failed to retrieve device details: $e');
    }
  }
}
