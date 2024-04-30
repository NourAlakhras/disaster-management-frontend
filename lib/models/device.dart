import 'package:flutter_3/utils/enums.dart'; // Import enums file

class Device {
  final String id;
  final String name;
  final DeviceType type;
  final Status status;

  Device({
    required this.id,
    required this.name,
    this.type = DeviceType.UGV, // Provide default value for type
    this.status = Status.AVAILABLE, // Provide default value for status
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: _getType(json['type'] as int?), // Add null check and cast to int
      status:
          _getStatus(json['status'] as int?), // Add null check and cast to int
    );
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

  static Status _getStatus(int? statusValue) {
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
