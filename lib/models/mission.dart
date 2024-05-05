import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/user.dart';
import 'package:intl/intl.dart'; // Import the intl package

class Mission {
  final String id;
  final String name;
  final MissionStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<Device>? devices;
  final List<User>? users;

  Mission({
    required this.id,
    required this.name,
    this.status,
    this.startDate,
    this.endDate,
    this.devices,
    this.users,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    List<Device> devices = [];
    if (json['devices'] != null) {
      devices = List<Device>.from(
          json['devices'].map((deviceJson) => Device.fromJson(deviceJson)));
    }

    List<User> users = [];
    if (json['users'] != null) {
      users = List<User>.from(
          json['users'].map((userJson) => User.fromJson(userJson)));
    }

    DateTime? startDate;
    if (json['start_date'] != null) {
      startDate =
          DateFormat('E, dd MMM yyyy HH:mm:ss').parse(json['start_date']);
    }

    DateTime? endDate;
    if (json['end_date'] != null) {
      endDate = DateFormat('E, dd MMM yyyy HH:mm:ss').parse(json['end_date']);
    }

    MissionStatus? status;
    if (json['status'] != null) {
      status = _getStatus(json['status']);
    }

    return Mission(
      id: json['id'],
      name: json['name'],
      startDate: startDate,
      endDate: endDate,
      status: status,
      devices: devices,
      users: users,
    );
  }

  static MissionStatus? _getStatus(dynamic statusValue) {
    if (statusValue == null) {
      return null; // Return null if statusValue is null
    } else if (statusValue is int) {
      return missionStatusValues.entries
          .firstWhere(
            (entry) => entry.value == statusValue,
            orElse: () => MapEntry(
                MissionStatus.CREATED, statusValues[MissionStatus.CREATED]!),
          )
          .key;
    } else {
      throw Exception('Invalid status value in API response: $statusValue');
    }
  }
}
