import 'dart:ui';

import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/services/mission_api_service.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/user.dart';
import 'package:intl/intl.dart'; // Import the intl package

class Mission {
  String id;
  String name;
  MissionStatus? status;
  DateTime? startDate;
  DateTime? endDate;
  List<Device>? devices;
  List<User>? users;
  Device? broker;

  Mission({
    required this.id,
    required this.name,
    this.status,
    this.startDate,
    this.endDate,
    this.devices,
    this.users,
    this.broker,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    List<Device> devices = [];
    Device? brokerDevice; // Define a variable to hold the broker device

    if (json['devices'] != null) {
      devices = List<Device>.from(
        json['devices'].map((deviceJson) => Device.fromJson(deviceJson)),
      );
    }

    if (json['broker'] != null) {
      brokerDevice = Device(
        device_id: json['broker']['broker_id'] as String? ?? '',
        name: json['broker']['broker_name'] as String? ?? '',
      );
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

    return Mission(
      id: json['mission_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'],
      startDate: startDate,
      endDate: endDate,
      status: json.containsKey('status') ? _getStatus(json['status']) : null,
      devices: devices,
      users: users,
      broker: brokerDevice,
    );
  }

  static MissionStatus? _getStatus(dynamic statusValue) {
    if (statusValue == null) {
      return null; // Return null if statusValue is null
    } else if (statusValue is int) {
      return missionStatusValues.entries
          .firstWhere(
            (entry) => entry.value == statusValue,
            orElse: () => MapEntry(MissionStatus.CREATED,
                missionStatusValues[MissionStatus.CREATED]!),
          )
          .key;
    } else {
      throw Exception('Invalid status value in API response: $statusValue');
    }
  }

  Future<void> fetchMissionDetails(VoidCallback setStateCallback) async {
    setStateCallback(); // Notify the widget to start loading

    try {
      final missionDetails = await MissionApiService.getMissionDetails(id);

      name = missionDetails.name;
      startDate = missionDetails.startDate;
      endDate = missionDetails.endDate;
      status = missionDetails.status;
      devices = missionDetails.devices;
      users = missionDetails.users;
      broker = missionDetails.broker;

      setStateCallback(); // Notify the widget that loading is complete
    } catch (e) {
      print('Error fetching mission info: $e');
      setStateCallback(); // Notify the widget even in case of an error
    }
  }

  Future<void> fetchDetailedDeviceInfo() async {
    if (devices != null) {
      for (int i = 0; i < devices!.length; i++) {
        devices![i] =
            await DeviceApiService.getDeviceDetails(devices![i].device_id);
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mission && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
  @override
  String toString() {
    return 'Mission(id: $id, name: $name, status: $status, startDate: $startDate, endDate: $endDate, devices: $devices, broker: $broker, users: $users)';
  }
}
