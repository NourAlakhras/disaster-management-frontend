import 'package:flutter_3/utils/enums.dart'; // Import enums file

class Device {
  final String id;
  final String name;
  final DeviceType? type;
  final DeviceStatus? status;

  Device({
    required this.id,
    required this.name,
    this.type,
    this.status,
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
    return 'Device {id: $id, name: $name, type: $type, status: $status}';
  }

}
