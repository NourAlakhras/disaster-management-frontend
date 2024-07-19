import 'package:flutter/material.dart';
import 'package:flutter_3/models/gps_data.dart';
import 'package:flutter_3/models/sensor_data.dart';

class SensorDataProvider with ChangeNotifier {
  Map<String, SensorData> _sensorData = {};
  Map<String, GPSData> _gpsData = {};

  Map<String, SensorData> get sensorData => _sensorData;
  Map<String, GPSData> get gpsData => _gpsData;

  void updateSensorData(String deviceName, SensorData sensorReading) {
    final key = '$deviceName/${sensorReading.sensor}';
    _sensorData[key] = sensorReading;
    notifyListeners();
  }

  void updateGPSData(String deviceName, GPSData gpsData) {
    final key = '$deviceName/gps';
    _gpsData[key] = gpsData;
    notifyListeners();
  }

  void handleIncomingData(String deviceName, Map<String, dynamic> data) {
    try {
      if (data.containsKey('sensor')) {
        _handleSensorData(deviceName, data);
      } else if (data.containsKey('lat') && data.containsKey('long')) {
        _handleGPSData(deviceName, data);
      } else {
        _logWarning('Received data does not match any expected format', data);
      }
    } catch (e) {
      _logError('Error handling incoming data', e, data);
    }
  }

  void _handleSensorData(String deviceName, Map<String, dynamic> data) {
    try {
      String sensor = data['sensor']?.toString() ?? 'Unknown';
      String unit = data['unit']?.toString() ?? '';
      var value = data['value'];

      if (value == null) {
        throw ArgumentError('Value cannot be null');
      }

      if (value is List) {
        for (var item in value) {
          if (item is num) {
            final sensorReading = SensorData(
              sensor: sensor,
              value: item,
              unit: unit,
            );
            updateSensorData(deviceName, sensorReading);
          } else {
            _logWarning('Received item in list is not a num', item);
          }
        }
      } else if (value is num) {
        final sensorReading = SensorData(
          sensor: sensor,
          value: value,
          unit: unit,
        );
        updateSensorData(deviceName, sensorReading);
      } else {
        _logWarning('Received value is not a num or List<num>', value);
      }
    } catch (e) {
      _logError('Error processing sensor data', e, data);
    }
  }

  void _handleGPSData(String deviceName, Map<String, dynamic> data) {
    try {
      double lat = data['lat']?.toDouble() ?? 0.0;
      double long = data['long']?.toDouble() ?? 0.0;

      final gpsData = GPSData(lat: lat, long: long);
      updateGPSData(deviceName, gpsData);
    } catch (e) {
      _logError('Error processing GPS data', e, data);
    }
  }

  void _logWarning(String message, [dynamic detail]) {
    print('WARNING: $message');
    if (detail != null) {
      print('Detail: $detail');
    }
  }

  void _logError(String message, dynamic error, [dynamic data]) {
    print('ERROR: $message');
    print('Error details: $error');
    if (data != null) {
      print('Data that caused the error: $data');
    }
  }

  Map<String, SensorData> getFilteredSensorData(List<String> deviceNames) {
    return Map.fromEntries(
      _sensorData.entries.where(
          (entry) => deviceNames.any((name) => entry.key.startsWith(name))),
    );
  }

  Map<String, GPSData> getFilteredGPSData(List<String> deviceNames) {
    return Map.fromEntries(
      _gpsData.entries.where(
          (entry) => deviceNames.any((name) => entry.key.startsWith(name))),
    );
  }
}
