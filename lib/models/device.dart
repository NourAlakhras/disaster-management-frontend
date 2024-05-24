import 'dart:ui';

import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/utils/enums.dart'; // Import enums file

class Device {
  final String device_id;
  String name;
  String? mac;
  DeviceType? type;
  DeviceStatus? status;
  Mission? mission;

  Device(
      {required this.device_id,
      required this.name,
      this.mac,
      this.type,
      this.status,
      this.mission});

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      device_id: json['id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      mac: json['mac'] != null ? json['mac'] as String? ?? '' : '',
      type: json.containsKey('type') ? _getType(json['type']) : null,
      status: json.containsKey('status') ? _getStatus(json['status']) : null,
      mission: json.containsKey('mission')
          ?Mission.fromJson(json['mission'] as Map<String, dynamic>)
          : null,
    );
  }

  Future<void> fetchDeviceDetails(VoidCallback setStateCallback) async {
    setStateCallback(); // Notify the widget to start loading

    try {

      final deviceDetails = await DeviceApiService.getDeviceDetails(device_id);

      name = deviceDetails.name;
      mac = deviceDetails.mac;
      type = deviceDetails.type;
      status = deviceDetails.status;
      status = deviceDetails.status;
      mission = deviceDetails.mission;
      
      setStateCallback(); // Notify the widget that loading is complete
    } catch (e) {
      print('Error fetching mission info: $e');
      setStateCallback(); // Notify the widget even in case of an error
    }
  }
  static DeviceType _getType(int? typeValue) {
    if (typeValue == null) {
      return DeviceType.UGV; // Default to UGV if type is null
    }
    return DeviceType.values.firstWhere(
      (type) => type.index + 1 == typeValue,
      orElse: () => DeviceType.UGV, // Default to UGV if type not found
    );
  }

  static DeviceStatus _getStatus(int? statusValue) {
    if (statusValue == null) {
      return DeviceStatus.AVAILABLE; // Default to AVAILABLE if status is null
    }
    return DeviceStatus.values.firstWhere(
      (status) => status.index + 1 == statusValue,
      orElse: () =>
          DeviceStatus.AVAILABLE, // Default to AVAILABLE if status not found
    );
  }

  @override
  String toString() {
    return 'Device {id: $device_id, name: $name, mac: $mac, type: $type, status: $status, mission $mission }';
  }
}
