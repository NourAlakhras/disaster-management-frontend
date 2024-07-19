class SensorData {
  final String sensor;
  final dynamic value;
  final String unit;

  SensorData({
    required this.sensor,
    required this.value,
    required this.unit,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      sensor: json['sensor'],
      value: json['value'],
      unit: json['unit'],
    );
  }
}
