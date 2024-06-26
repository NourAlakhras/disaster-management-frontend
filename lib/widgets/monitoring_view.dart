import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';

class MonitoringView extends StatefulWidget {
  final String deviceId;
  final MQTTClientWrapper mqttClient;

  const MonitoringView({
    super.key,
    required this.deviceId,
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
      '${widget.deviceId}/gps',//cloud/reg/<broker_name>/<device_name>/gps:
      '${widget.deviceId}/sensor_data',//cloud/reg/<broker_name>/<device_name>/sensor-data:
      '${widget.deviceId}/connectivity',
      '${widget.deviceId}/battery',
    ]);
    widget.mqttClient.setupMessageListener();
  }

  void _onDataReceived(Map<String, dynamic> data) {
    if (data.containsKey('lat') && data.containsKey('long')) {
      final latitude = data['lat'] ?? 0.0;
      final longitude = data['long'] ?? 0.0;
      // Update device's location
      setState(() {
        _deviceLocation = LatLng(latitude, longitude);
        // Update camera position to center on the device's location
        _updateCameraPosition(_deviceLocation);
        // Update marker position
        _updateMarker(_deviceLocation);
      });
    } else if (data.containsKey('wifi')) {
      setState(() {
      });
    } else if (data.containsKey('battery')) {
      final batteryLevel = data['battery'] ?? 0.0;
      setState(() {
      });
    } else {
      // Handle other sensor data here
      data.forEach((key, value) {
        setState(() {
          _sensorData[key] = value;
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

  final Map<String, IconData> iconMap = {
    'Location': Icons.map_outlined,
    'Operating Status': Icons.directions_run,
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

  final List<String> allKeys = [
    'Location',
    'Operating Status',
    'id',
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
        if (index == 0) {
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xff293038),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: Colors.white,
                    ),
                  ),
                ),
                title: Text(
                  key,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                  myLocationButtonEnabled:
                      true, 
                  rotateGesturesEnabled: true, // Respond to rotate gestures
                  tiltGesturesEnabled: true, // Respond to tilt gestures
                  zoomControlsEnabled: true, // Show zoom controls
                  zoomGesturesEnabled: true, // Respond to zoom gestures
                  initialCameraPosition: CameraPosition(
                    target:
                        _deviceLocation, // Set initial camera position to device's location
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
                color: const Color(0xff293038),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                ),
              ),
            ),
            title: Text(
              key,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              value.toString(),
              style: const TextStyle(
                color: Colors.white70,
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
      '${widget.deviceId}/gps',
      '${widget.deviceId}/sensor_data',
      '${widget.deviceId}/connectivity',
      '${widget.deviceId}/battery',
    ]);
    super.dispose();
  }
}
