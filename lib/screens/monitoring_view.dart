import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/sensor_data.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_3/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:flutter_3/providers/sensor_data_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MonitoringView extends StatefulWidget {
  final Device device;

  const MonitoringView({
    super.key,
    required this.device,
  });

  @override
  _MonitoringViewState createState() => _MonitoringViewState();
}

class _MonitoringViewState extends State<MonitoringView> {
  GoogleMapController? _controller;
  late LatLng _deviceLocation;
  final Set<Marker> _markers = {};
  final Map<String, Map<String, double>> thresholds = {};

  @override
  void initState() {
    super.initState();
    _deviceLocation = const LatLng(0.0, 0.0);
    _loadThresholds();
  }

  Future<void> _loadThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.endsWith('_low') || key.endsWith('_high')) {
        final sensorKey = key.replaceAll('_low', '').replaceAll('_high', '');
        if (!thresholds.containsKey(sensorKey)) {
          thresholds[sensorKey] = {'low': 0.0, 'high': 0.0};
        }
        if (key.endsWith('_low')) {
          thresholds[sensorKey]!['low'] = prefs.getDouble(key) ?? 0.0;
        } else if (key.endsWith('_high')) {
          thresholds[sensorKey]!['high'] = prefs.getDouble(key) ?? 0.0;
        }
      }
    }
    setState(() {});
  }

  Future<void> _saveThresholds(String key, double low, double high) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${key}_low', low);
    await prefs.setDouble('${key}_high', high);
  }

  List<Widget> _buildSensorDataTiles(Map<String, SensorData> sensorData) {
    return sensorData.entries.map((entry) {
      final key = _normalizeSensorName(entry.key.split('/').last);
      final sensorData = entry.value;
      final sensorStatus = _getSensorStatus(key, sensorData.value);
      final icon = iconMap[key] ?? Icons.info;

      Color getStatusColor() {
        switch (sensorStatus) {
          case 'low':
            return lowValueColor;
          case 'high':
            return highValueColor;
          case 'normal':
            return normalValueColor;
          default:
            return noValueColor;
        }
      }

      return ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: getStatusColor(),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              icon,
              color: primaryTextColor,
            ),
          ),
        ),
        title: Text(
          key[0].toUpperCase() + key.substring(1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        subtitle: Text(
          '${sensorData.value} ${sensorData.unit}',
          style: const TextStyle(
            color: secondaryTextColor,
          ),
        ),
        onTap: () => _showThresholdDialog(key),
      );
    }).toList();
  }

  void _updateCameraPosition(LatLng target) {
    if (_controller != null) {
      _controller!.animateCamera(CameraUpdate.newLatLng(target));
    }
  }

  void _updateMarker(LatLng location) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('device_marker'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  String _normalizeSensorName(String sensorName) {
    final normalized =
        sensorName.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    return normalized
        .split(' ')
        .first; // Take the first part of the name for simplicity
  }

  String _getSensorStatus(String key, dynamic value) {
    if (value is! num) {
      return 'unknown';
    }
    if (thresholds.containsKey(key)) {
      final threshold = thresholds[key]!;
      if (value < threshold['low']!) {
        return 'low';
      } else if (value > threshold['high']!) {
        return 'high';
      } else {
        return 'normal';
      }
    }
    return 'unknown';
  }

  // Define icon mapping
  final Map<String, IconData> iconMap = {
    'location': Icons.map_outlined,
    'battery': Icons.battery_full,
    'temperature': Icons.thermostat,
    'humidity': Icons.water_drop,
    'gas': Icons.air,
    'air quality': Icons.waves,
    'smoke detection': Icons.smoke_free,
    'earthquake detection': Icons.public,
    'radiation level': Icons.radar,
    'sound level': Icons.volume_up,
    'distance': Icons.map_outlined,
    'light': Icons.lightbulb_outline,
    'timestamp': Icons.access_time,
    'tvoc': Icons.local_fire_department,
    'total volatile organic compounds': Icons.local_fire_department,
    'accelerometer': Icons.device_unknown,
    'gyroscope': Icons.motion_photos_on,
    'gyro': Icons.motion_photos_on, // Common abbreviation for gyroscope
    'ir': Icons.videocam,
    'infrared': Icons.videocam,
    'ultrasonic': Icons.waves,
    'sound': Icons.volume_up,
    'pressure': Icons.trending_up,
    'magnetometer': Icons.devices,
    'gps': Icons.location_on,
    'altimeter': Icons.navigation,
    'proximity': Icons.location_searching,
    'current': Icons.flash_on,
    'vibration': Icons.vibration,
    'particulate matter': Icons.filter_list,
    'oxygen level': Icons.local_airport,
    'co2': Icons.air,
    'uv index': Icons.wb_sunny,
    'noise level': Icons.volume_down,

    // Add more abbreviations if needed
    'co2 level': Icons.air,
    'pm2.5': Icons.filter_list, // Particulate matter 2.5
    'pm10': Icons.filter_list, // Particulate matter 10
  };

  void _showThresholdDialog(String key) {
    final currentLow = thresholds[key]?['low'] ?? '';
    final currentHigh = thresholds[key]?['high'] ?? '';

    final TextEditingController lowController =
        TextEditingController(text: currentLow.toString());
    final TextEditingController highController =
        TextEditingController(text: currentHigh.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Thresholds for $key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: lowController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Low Threshold',
                ),
              ),
              TextField(
                controller: highController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'High Threshold',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final lowThreshold = double.tryParse(lowController.text);
                final highThreshold = double.tryParse(highController.text);

                if (lowThreshold != null && highThreshold != null) {
                  setState(() {
                    thresholds[key] = {
                      'low': lowThreshold,
                      'high': highThreshold,
                    };
                  });
                  await _saveThresholds(key, lowThreshold, highThreshold);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorDataProvider>(
      builder: (context, sensorDataProvider, child) {
        final deviceSensorData =
            sensorDataProvider.getFilteredSensorData([widget.device.name]);
        final deviceGPSData =
            sensorDataProvider.getFilteredGPSData([widget.device.name]);

        if (deviceGPSData.isNotEmpty) {
          final gpsData = deviceGPSData.values.first;
          _deviceLocation = LatLng(gpsData.lat, gpsData.long);
          _updateCameraPosition(_deviceLocation);
          _updateMarker(_deviceLocation);
        }

        return ListView(
          children: [
            if (deviceGPSData.isNotEmpty) ...[
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: noValueColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.map_outlined,
                      color: primaryTextColor,
                    ),
                  ),
                ),
                title: const Text(
                  'GPS Location',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                subtitle: Text(
                  '${_deviceLocation.latitude}, ${_deviceLocation.longitude}',
                  style: const TextStyle(
                    color: secondaryTextColor,
                  ),
                ),
                onTap: () {},
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                height: MediaQuery.of(context).size.height / 3,
                width: double.infinity,
                child: GoogleMap(
                  gestureRecognizers: {}
                    ..add(Factory<PanGestureRecognizer>(
                        () => PanGestureRecognizer()))
                    ..add(Factory<ScaleGestureRecognizer>(
                        () => ScaleGestureRecognizer()))
                    ..add(Factory<TapGestureRecognizer>(
                        () => TapGestureRecognizer()))
                    ..add(Factory<VerticalDragGestureRecognizer>(
                        () => VerticalDragGestureRecognizer()))
                    ..add(Factory<HorizontalDragGestureRecognizer>(
                        () => HorizontalDragGestureRecognizer()))
                    ..add(Factory<LongPressGestureRecognizer>(
                        () => LongPressGestureRecognizer())),
                  compassEnabled: true,
                  buildingsEnabled: true,
                  mapType: MapType.normal,
                  indoorViewEnabled: true,
                  myLocationButtonEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  zoomControlsEnabled: true,
                  zoomGesturesEnabled: true,
                  myLocationEnabled: false,
                  initialCameraPosition: CameraPosition(
                    target: _deviceLocation,
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  onMapCreated: (GoogleMapController controller) {
                    _controller = controller;
                  },
                ),
              ),
            ],
            if (deviceSensorData.isNotEmpty) ...[
              ..._buildSensorDataTiles(deviceSensorData),
            ],
          ],
        );
      },
    );
  }
}
