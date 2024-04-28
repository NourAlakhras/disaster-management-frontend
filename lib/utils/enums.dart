// lib\utils\enums.dart
// Define the Status enum with specific numbers assigned to each enum value
enum Status {
  AVAILABLE,
  PENDING,
  ASSIGNED,
  INACTIVE,
  REJECTED,
}

// Map each enum value to its corresponding number
final statusValues = {
  Status.AVAILABLE: 1,
  Status.PENDING: 2,
  Status.ASSIGNED: 3,
  Status.INACTIVE: 4,
  Status.REJECTED: 5,
};

enum UserType { REGULAR, ADMIN }

final userTypeValues = {UserType.REGULAR: 1, UserType.ADMIN: 2};

enum MissionStatus {
  CREATED,
  ONGOING,
  PAUSED,
  CANCELED,
  FINISHED,
}

final missionStatusValues = {
  MissionStatus.CREATED: 1,
  MissionStatus.ONGOING: 2,
  MissionStatus.PAUSED: 3,
  MissionStatus.CANCELED: 4,
  MissionStatus.FINISHED: 5,
};
enum DeviceType {
  UGV,
  UAV,
  DOG,
  CHARGING_STATION,
  BROKER,
}

final DeviceTypeValues = {
  DeviceType.UGV: 1,
  DeviceType.UAV: 2,
  DeviceType.DOG: 3,
  DeviceType.CHARGING_STATION: 4,
  DeviceType.BROKER: 5,
};

enum DeviceStatus {
  AVAILABLE,
  ASSIGNED,
  INACTIVE,
}

final DeviceStatusValues = {
  DeviceStatus.AVAILABLE: 1,
  DeviceStatus.ASSIGNED: 2,
  DeviceStatus.INACTIVE: 3,
};
