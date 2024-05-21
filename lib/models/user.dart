// lib\models\user.dart
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/models/mission.dart';

class User {
  String user_id;
  String username;
  String? email;
  UserType? type;
  UserStatus? status;
  int? activeMissionCount;
  List<Mission>? missions;

  User({
    required this.user_id,
    required this.username,
    this.email,
    this.type,
    this.status,
    this.activeMissionCount,
    this.missions,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      user_id: json['user_id'] as String? ?? json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] != null ? json['email'] as String? ?? '' : '',
      type: json.containsKey('type') ? _getType(json['type']) : null,
      status: json.containsKey('status') ? _getStatus(json['status']) : null,
      activeMissionCount: json['active_mission_count'] != null
          ? json['active_mission_count'] as int
          : 0,
      missions: json.containsKey('missions')
          ? List<Mission>.from(json['missions'].map((missionJson) =>
              Mission.fromJson(missionJson as Map<String, dynamic>)))
          : null,
    );
  }

  static UserType? _getType(dynamic typeValue) {
    if (typeValue == null) return null;
    return userTypeValues.entries
        .firstWhere((entry) => entry.value == typeValue,
            orElse: () =>
                MapEntry(UserType.REGULAR, userTypeValues[UserType.REGULAR]!))
        .key;
  }

  static UserStatus? _getStatus(dynamic statusValue) {
    if (statusValue == null) return null;
    return userStatusValues.entries
        .firstWhere((entry) => entry.value == statusValue,
            orElse: () => MapEntry(
                UserStatus.AVAILABLE, userStatusValues[UserStatus.AVAILABLE]!))
        .key;
  }

  @override
  String toString() {
    return 'User {user_id: $user_id, username: $username, email: $email, type: $type, status: $status, missions: $missions, activeMissionCount: $activeMissionCount}';
  }
}
