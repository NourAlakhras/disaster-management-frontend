import 'package:flutter_3/utils/enums.dart';

class Mission {
  final String id;
  final String name;
  final MissionStatus status;

  Mission({
    required this.id,
    required this.name,
    required this.status,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: _getStatus(json['status']) ,
    );
  }

  static MissionStatus _getStatus(int statusValue) {
    return missionStatusValues.entries
        .firstWhere((entry) => entry.value == statusValue,
            orElse: () =>
                MapEntry(
                MissionStatus.CREATED, statusValues[MissionStatus.CREATED]!))
        .key;
  }
}


