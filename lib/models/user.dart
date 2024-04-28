// lib\models\user.dart
import 'package:flutter_3/utils/enums.dart';

class User {
  final String id;
  final String username;
  final UserType type;
  final Status status; 
  final int activeMissionCount;

  User({
    required this.id,
    required this.username,
    required this.type,
    required this.status,
    required this.activeMissionCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      type: _getUserType(json['type']),
      status: _getStatus(json['status']),
      activeMissionCount: json['active_mission_count'],
    );
  }

  static UserType _getUserType(int typeValue) {
    return userTypeValues.entries
        .firstWhere((entry) => entry.value == typeValue,
            orElse: () =>
                MapEntry(UserType.REGULAR, userTypeValues[UserType.REGULAR]!))
        .key;
  }

  static Status _getStatus(int statusValue) {
    return statusValues.entries
        .firstWhere((entry) => entry.value == statusValue,
            orElse: () =>
                MapEntry(Status.AVAILABLE, statusValues[Status.AVAILABLE]!))
        .key;
  }
}
