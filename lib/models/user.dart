// lib\models\user.dart
import 'package:flutter_3/utils/enums.dart';

class User {
  final String id;
  final String username;
  final UserType? type;
  final UserStatus? status;
  final int? activeMissionCount;

  User({
    required this.id,
    required this.username,
    this.type,
    this.status,
    this.activeMissionCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      type: json.containsKey('type') ? _getUserType(json['type']) : null,
      status: json.containsKey('status') ? _getStatus(json['status']) : null,
      activeMissionCount: json.containsKey('active_mission_count')
          ? json['active_mission_count']
          : null,
    );
  }

  static UserType _getUserType(int typeValue) {
    return userTypeValues.entries
        .firstWhere((entry) => entry.value == typeValue,
            orElse: () =>
                MapEntry(UserType.REGULAR, userTypeValues[UserType.REGULAR]!))
        .key;
  }

  static UserStatus _getStatus(int statusValue) {
    return userStatusValues.entries
        .firstWhere((entry) => entry.value == statusValue,
            orElse: () =>
                MapEntry(UserStatus.AVAILABLE, userStatusValues[UserStatus.AVAILABLE]!))
        .key;
  }

  @override
  String toString() {
    return 'User {id: $id, username: $username, type: $type, status: $status, activeMissionCount: $activeMissionCount}';
  }
}
