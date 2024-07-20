import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/services/mission_api_service.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/user.dart';
import 'package:intl/intl.dart';

class Mission {
  String id;
  String _name;
  MissionStatus? status;
  DateTime? startDate;
  DateTime? endDate;
  List<Device>? devices;
  List<User>? users;
  Device? broker;

  Mission({
    required this.id,
    required String name,
    required this.broker,
    this.status,
    this.startDate,
    this.endDate,
    this.devices,
    this.users,
  }) : _name = validateName(name) ? name : '';

  static bool validateName(String name) {
    return name.isNotEmpty && name.length >= 3 && name.length <= 20;
  }

  String get name => _name;

  set name(String value) {
    if (validateName(value)) {
      _name = value;
    } else {
      throw ArgumentError('Mission name must be between 3 and 20 characters');
    }
  }

  factory Mission.fromJson(Map<String, dynamic> json) {
    List<Device> devices = [];
    Device? brokerDevice;

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
        json['users'].map((userJson) => User.fromJson(userJson)),
      );
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
      name: json['name'] as String? ?? '',
      broker: brokerDevice,
      startDate: startDate,
      endDate: endDate,
      status: json.containsKey('status') ? _getStatus(json['status']) : null,
      devices: devices,
      users: users,
    );
  }

  Future<void> fetchMissionDetails(VoidCallback setStateCallback) async {
    setStateCallback();

    try {
      final missionDetails = await MissionApiService.getMissionDetails(id);

      name = missionDetails.name;
      startDate = missionDetails.startDate;
      endDate = missionDetails.endDate;
      status = missionDetails.status;
      devices = missionDetails.devices;
      users = missionDetails.users;
      broker = missionDetails.broker;
      print(missionDetails);
    } catch (e) {
      print('Error fetching mission info: $e');
    } finally {
      setStateCallback();
    }
  }

  Future<void> fetchDetailedDeviceInfo({required BuildContext context}) async {
    if (devices != null) {
      await Future.wait(devices!.map((device) async {
        final detailedDevice = await DeviceApiService.getDeviceDetails(
            deviceId: device.device_id, context: context);
        return detailedDevice;
      }).toList())
          .then((updatedDevices) {
        devices = updatedDevices;
      }).catchError((e) {
        print('Error fetching device details: $e');
      });
    }
  }

  static MissionStatus? _getStatus(dynamic statusValue) {
    if (statusValue == null) {
      return null;
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

  Future<String?> createMission({
    required String missionName,
    required List<String> userIds,
    required String brokerId,
    required List<String> deviceIds,
  }) async {
    try {
      final String? missionId = await MissionApiService.createMission(
        name: missionName,
        deviceIds: deviceIds,
        userIds: userIds,
        brokerId: brokerId,
      );
      return missionId;
    } catch (e) {
      print('Failed to create mission: $e');
      return null;
    }
  }

  Future<void> start(VoidCallback updateState) async {
    await _updateMissionStatus("start", updateState);
  }

  Future<void> pause(VoidCallback updateState) async {
    await _updateMissionStatus("pause", updateState);
  }

  Future<void> end(VoidCallback updateState) async {
    await _updateMissionStatus("end", updateState);
  }

  Future<void> cancel(VoidCallback updateState) async {
    await _updateMissionStatus("cancel", updateState);
  }

  Future<void> resume(VoidCallback updateState) async {
    await _updateMissionStatus("continue", updateState);
  }

  Future<void> _updateMissionStatus(
      String command, VoidCallback updateState) async {
    try {
      await MissionApiService.updateMissionStatus(id, command);
      await fetchMissionDetails(updateState);
    } catch (error) {
      print('Failed to update mission status: $error');
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
