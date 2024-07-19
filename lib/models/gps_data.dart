import 'dart:ffi';

class GPSData {
  final double lat;
  final double long;

  GPSData({required this.lat, required this.long});

  factory GPSData.fromJson(Map<String, dynamic> json) {
    return GPSData(
      lat: json['lat'],
      long: json['long'],
    );
  }
}
