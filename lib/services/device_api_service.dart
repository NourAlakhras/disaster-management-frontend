import 'dart:convert';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/services/auth_api_service.dart';
import 'package:flutter_3/utils/constants.dart';
import 'package:flutter_3/utils/exceptions.dart';
import 'package:http/http.dart' as http;

class DeviceApiService {
  static Future<List<Device>> getAllDevices({
    int pageNumber = 1,
    int pageSize = 5,
    int? status,
    int? type,
    String? missionId,
  }) async {
    final String baseUrl = Constants.baseUrl;
    final String queryString = _buildQueryString(
      pageNumber: pageNumber,
      pageSize: pageSize,
      status: status,
      type: type,
      missionId: missionId,
    );

    final Uri url = Uri.parse('$baseUrl/api/devices/all?$queryString');

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
        return responseBody.map((json) => Device.fromJson(json)).toList();
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
      throw Exception('Failed to get devices: $e');
    }
  }

  static String _buildQueryString({
    int pageNumber = 1,
    int pageSize = 5,
    int? status,
    int? type,
    String? missionId,
  }) {
    String queryString = 'page-number=$pageNumber&page-size=$pageSize';
    if (status != null) queryString += '&status=$status';
    if (type != null) queryString += '&type=$type';
    if (missionId != null) queryString += '&mission=$missionId';
    return queryString;
  }
}
