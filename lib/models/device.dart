import 'package:flutter/material.dart';
import 'package:flutter_3/utils/enums.dart'; // Import enums file

class Device {
  final String id;
  final String name;
  final String mac;
  final DeviceType type;
  final Status status;

  Device({
    required this.id,
    required this.name,
    required this.mac,
    required this.type,
    required this.status,
  });
  
factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      mac: json['mac'] ?? '',
      type: _getType(json['type'] as int?), // Add null check and cast to int
      status:
          _getStatus(json['status'] as int?), // Add null check and cast to int
    );
  }

static DeviceType _getType(int? typeValue) {
    // Update parameter type to accept nullable int
    if (typeValue == null) {
      return DeviceType.UGV; // Default to UGV if type is null
    }
    return DeviceType.values.firstWhere(
      (type) => type.index + 1 == typeValue,
      orElse: () => DeviceType.UGV, // Default to UGV if type not found
    );
  }

  static Status _getStatus(int? statusValue) {
    // Update parameter type to accept nullable int
    if (statusValue == null) {
      return Status.AVAILABLE; // Default to AVAILABLE if status is null
    }
    return Status.values.firstWhere(
      (status) => status.index + 1 == statusValue,
      orElse: () =>
          Status.AVAILABLE, // Default to AVAILABLE if status not found
    );
  }

}
