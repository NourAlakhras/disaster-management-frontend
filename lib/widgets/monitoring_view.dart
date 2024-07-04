import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_3/utils/app_colors.dart';

class MonitoringView extends StatefulWidget {
  final Device device;
  final MQTTClientWrapper mqttClient;

  const MonitoringView({
    super.key,
    required this.device,
    required this.mqttClient,
  });

  @override
  _MonitoringViewState createState() => _MonitoringViewState();
}

class _MonitoringViewState extends State<MonitoringView> {
  late GoogleMapController _controller;
  late LatLng _deviceLocation;
  final Set<Marker> _markers = {};
  late Map<String, dynamic> _sensorData;

  @override
  void initState() {
    super.initState();
    _deviceLocation = const LatLng(0.0, 0.0);
    _sensorData = {};

    widget.mqttClient.onDataReceived = _onDataReceived;
    widget.mqttClient.subscribeToMultipleTopics([
      'test-ugv/sensor_data',
      '${widget.device.name}/gps',
      '${widget.device.name}/sensor_data',
      '${widget.device.name}/connectivity',
      '${widget.device.name}/battery',
    ]);
    widget.mqttClient.setupMessageListener();
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
    // } else if (data.containsKey('wifi')) {
    //   setState(() {});
    // } else if (data.containsKey('battery')) {
    //   final batteryLevel = data['battery'] ?? 0.0;
    //   setState(() {});
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
          );
        }
      },
    );
  }

  @override
  void dispose() {
    widget.mqttClient.unsubscribeFromMultipleTopics([
      'test-ugv/sensor_data',
      '${widget.device.name}/gps',
      '${widget.device.name}/sensor_data',
      '${widget.device.name}/connectivity',
      '${widget.device.name}/battery',
    ]);
    super.dispose();
  }
}
