import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_3/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MonitoringView extends StatefulWidget {
  final Device device;
  final MQTTClientWrapper mqttClient;
  final Device? broker;
  const MonitoringView({
    super.key,
    required this.device,
    required this.mqttClient,
    required this.broker
  });

  @override
  _MonitoringViewState createState() => _MonitoringViewState();
}
class _MonitoringViewState extends State<MonitoringView> {
  late GoogleMapController _controller;
  late LatLng _deviceLocation;
  final Set<Marker> _markers = {};
  late Map<String, dynamic> _sensorData;
  late List<String> mqttTopics;

  @override
  void initState() {
    super.initState();
    _deviceLocation = const LatLng(0.0, 0.0);
    _sensorData = {};
    _loadThresholds();

    mqttTopics = [
      'test-ugv/sensor_data',
      'cloud/reg/${widget.broker?.name}/${widget.device.name}/gps',
      'cloud/reg/${widget.broker?.name}/${widget.device.name}/sensor-data',
      'cloud/reg/${widget.broker?.name}/${widget.device.name}/connectivity',
      'cloud/reg/${widget.broker?.name}/${widget.device.name}/battery',
    ];

    widget.mqttClient.onDataReceived = _onDataReceived;
    widget.mqttClient.subscribeToMultipleTopics(mqttTopics);
    widget.mqttClient.setupMessageListener();
  }

  @override
  void dispose() {
    widget.mqttClient.unsubscribeFromMultipleTopics(mqttTopics);
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

  void _onDataReceived(Map<String, dynamic> data) {
    if (data.containsKey('lat') && data.containsKey('long')) {
      final latitude = data['lat'] ?? 0.0;
      final longitude = data['long'] ?? 0.0;
      setState(() {
        _deviceLocation = LatLng(latitude, longitude);
        _updateCameraPosition(_deviceLocation);
        _updateMarker(_deviceLocation);
      });
    } else {
      data.forEach((key, value) {
        setState(() {
          _sensorData[key.toLowerCase()] = value;
        });
      });
    }
  }

  void _updateCameraPosition(LatLng target) {
    _controller.animateCamera(CameraUpdate.newLatLng(target));
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
    'gas concentration': {'low': 0, 'high': 50},
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
    'Location': Icons.map_outlined,
    'Battery Status': Icons.battery_full,
    'Temperature': Icons.thermostat,
    'Humidity': Icons.water_drop,
    'Gas Concentration': Icons.air,
    'Air Quality': Icons.waves,
    'Smoke Detection': Icons.smoke_free,
    'Earthquake Detection': Icons.public,
    'Radiation Level': Icons.radar,
    'Sound Level': Icons.volume_up,
    'Distance': Icons.map_outlined,
    'Light': Icons.lightbulb_outline,
    'Timestamp': Icons.access_time,
  };

  // Define all keys
  final List<String> allKeys = [
    'Location',
    'Battery Status',
    'Temperature',
    'Humidity',
    'Gas Concentration',
    'Air Quality',
    'Smoke Detection',
    'Earthquake Detection',
    'Radiation Level',
    'Sound Level',
    'Distance',
    'Light',
    'Timestamp',
  ];

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
    return ListView.builder(
      itemCount: allKeys.length,
      itemBuilder: (context, index) {
        final key = allKeys[index];
        final value = _sensorData[key.toLowerCase()] ?? 'No data';
        final icon = iconMap[key] ?? Icons.info;
        final sensorStatus = _getSensorStatus(key.toLowerCase(), value);

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

        if (index == 0) {
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: barColor,
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
                  key,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
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
          );
           } else {
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
              key,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            subtitle: Text(
              value.toString(),
              style: const TextStyle(
                color: secondaryTextColor,
              ),
            ),
            onTap: () => _showThresholdDialog(key),
          );
        }
      },
    );
  }


}
