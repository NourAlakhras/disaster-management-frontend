// lib\models\user.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_3/services/admin_api_service.dart';
import 'package:flutter_3/services/user_api_service.dart';
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
      missions: json.containsKey('cur_missions')
          ? List<Mission>.from(json['cur_missions'].map((missionJson) =>
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

  Future<void> fetchUserDetails(
      {required context, required VoidCallback setStateCallback}) async {
    setStateCallback(); // Notify the widget to start loading

    try {
      final userDetails = await AdminApiService.getUserDetails(
          context: context, userId: user_id);

      username = userDetails.username;
      email = userDetails.email ?? 'No email available';
      status = userDetails.status;
      type = userDetails.type;
      activeMissionCount = userDetails.activeMissionCount;
      missions = userDetails.missions ?? [];

      setStateCallback(); // Notify the widget that loading is complete
    } catch (e) {
      print('Error fetching mission info: $e');
      setStateCallback(); // Notify the widget even in case of an error
    }
  }

  Future<void> approve(
      {required context,
      required bool isAdmin,
      required VoidCallback setStateCallback}) async {
    try {
      await AdminApiService.approveUser(
          context: context, userId: user_id, isAdmin: isAdmin);
      await fetchUserDetails(context: context,setStateCallback: setStateCallback);
    } catch (e) {
      print('Failed to approve user: $e');
      setStateCallback(); // Notify the widget even in case of an error
    }
  }

  Future<void> reject(
      {required context, required VoidCallback setStateCallback}) async {
    try {
      await AdminApiService.rejectUser(context: context, userId: user_id);
      await fetchUserDetails(
          context: context, setStateCallback: setStateCallback);
    } catch (e) {
      print('Failed to reject user: $e');
      setStateCallback(); // Notify the widget even in case of an error
    }
  }

  Future<void> delete(
      {required context, required VoidCallback setStateCallback}) async {
    try {
      await AdminApiService.deleteUser(context: context, userId: user_id);
      // Handle successful deletion, possibly notify the user or navigate away
    } catch (e) {
      print('Failed to delete user: $e');
      setStateCallback(); // Notify the widget even in case of an error
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          user_id == other.user_id;

  @override
  int get hashCode => user_id.hashCode;
  @override
  String toString() {
    return 'User {user_id: $user_id, username: $username, email: $email, type: $type, status: $status, missions: $missions, activeMissionCount: $activeMissionCount}';
  }
}
