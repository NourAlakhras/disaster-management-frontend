import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/sensor_data.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_3/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:flutter_3/providers/sensor_data_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Ensure this import path is correct

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
  GoogleMapController? _controller; // Nullable controller
  late LatLng _deviceLocation;
  final Set<Marker> _markers = {};
  late Map<String, dynamic> _sensorData;
  late Map<String, dynamic> _gpsData;

  @override
  void initState() {
    super.initState();
    _deviceLocation = const LatLng(0.0, 0.0);
    _sensorData = {};
    _gpsData = {};
    _loadThresholds();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    thresholds.forEach((key, value) {
      final low = prefs.getDouble('${key}_low') ?? value['low'];
      final high = prefs.getDouble('${key}_high') ?? value['high'];
      setState(() {
        thresholds[key] = {'low': low!, 'high': high!};
      });
    });
  }

  List<Widget> _buildSensorDataTiles(Map<String, SensorData> sensorData) {
    return sensorData.entries.map((entry) {
      final key = entry.key.split('/').last.toLowerCase();
      print('final key  $key // Extract sensor type from key');

      final sensorData = entry.value;
      final sensorStatus =
          _getSensorStatus(key.toLowerCase(), sensorData.value);
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
          key[0].toUpperCase() + key.substring(1).toLowerCase(),
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

  // Define thresholds for sensor data
  final Map<String, Map<String, double>> thresholds = {
    'temperature': {'low': 0, 'high': 30},
    'humidity': {'low': 30, 'high': 70},
    'gas': {'low': 0, 'high': 50},
    'air quality': {'low': 0, 'high': 100},
    'smoke detection': {'low': 0, 'high': 1},
    'earthquake detection': {'low': 0, 'high': 1},
    'radiation level': {'low': 0, 'high': 100},
    'sound level': {'low': 0, 'high': 70},
    'distance': {'low': 0, 'high': 100},
    'light': {'low': 0, 'high': 1000},
  };

  // Determine the status of the sensor data
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
    final currentLow = thresholds[key.toLowerCase()]?['low'] ?? '';
    final currentHigh = thresholds[key.toLowerCase()]?['high'] ?? '';

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
                    thresholds[key.toLowerCase()] = {
                      'low': lowThreshold,
                      'high': highThreshold,
                    };
                  });
                  await _saveThresholds(
                      key.toLowerCase(), lowThreshold, highThreshold);
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

  Future<void> _saveThresholds(String key, double low, double high) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('${key}_low', low);
    prefs.setDouble('${key}_high', high);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorDataProvider>(
      builder: (context, sensorDataProvider, child) {
        // Fetch filtered data based on the device name
        final deviceSensorData =
            sensorDataProvider.getFilteredSensorData([widget.device.name]);
        final deviceGPSData =
            sensorDataProvider.getFilteredGPSData([widget.device.name]);

        // Update device location based on GPS data
        if (deviceGPSData.isNotEmpty) {
          final gpsData = deviceGPSData
              .values.first; // Assuming only one GPS data entry per device
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
                    color: noValueColor, // Set a color for the icon background
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
                  indoorViewEnabled: true,
                  myLocationButtonEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  zoomControlsEnabled: true,
                  zoomGesturesEnabled: true,
                  initialCameraPosition: CameraPosition(
                    target: _deviceLocation,
                    zoom: 15.0,
                  ),
                  markers: _markers,
                  onMapCreated: (GoogleMapController controller) {
                    _controller = controller;
                  },
                ),
              ),
            ],
            ..._buildSensorDataTiles(deviceSensorData),
          ],
        );
      },
    );
  }
}
