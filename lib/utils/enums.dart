// Define the UserType enum with specific numbers assigned to each enum value
enum UserType {
  REGULAR,
  ADMIN,
}

// Map each enum value to its corresponding number
final userTypeValues = {
  UserType.REGULAR: 1,
  UserType.ADMIN: 2,
};

// Define the DeviceType enum with specific numbers assigned to each enum value
enum DeviceType {
  UGV,
  UAV,
  DOG,
  CHARGING_STATION,
  BROKER,
}

// Map each enum value to its corresponding number
final deviceTypeValues = {
  DeviceType.UGV: 1,
  DeviceType.UAV: 2,
  DeviceType.DOG: 3,
  DeviceType.CHARGING_STATION: 4,
  DeviceType.BROKER: 5,
};

// Define the UserStatus enum with specific numbers assigned to each enum value
enum UserStatus {
  PENDING,
  ACCEPTED,
  AVAILABLE,
  ASSIGNED,
  REJECTED,
  INACTIVE,
}

// Map each enum value to its corresponding number
final userStatusValues = {
  UserStatus.PENDING: 1,
  UserStatus.ACCEPTED: 2,
  UserStatus.AVAILABLE: 3,
  UserStatus.ASSIGNED: 4,
  UserStatus.REJECTED: 5,
  UserStatus.INACTIVE: 6,
};

// Define the DeviceStatus enum with specific numbers assigned to each enum value
enum DeviceStatus {
  AVAILABLE,
  ASSIGNED,
  INACTIVE,
}

// Map each enum value to its corresponding number
final deviceStatusValues = {
  DeviceStatus.AVAILABLE: 1,
  DeviceStatus.ASSIGNED: 2,
  DeviceStatus.INACTIVE: 3,
};

// Define the MissionStatus enum with specific numbers assigned to each enum value
enum MissionStatus {
  CREATED,
  ONGOING,
  PAUSED,
  CANCELED,
  FINISHED,
}

// Map each enum value to its corresponding number
final missionStatusValues = {
  MissionStatus.CREATED: 1,
  MissionStatus.ONGOING: 2,
  MissionStatus.PAUSED: 3,
  MissionStatus.CANCELED: 4,
  MissionStatus.FINISHED: 5,
};
