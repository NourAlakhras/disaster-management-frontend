import 'package:flutter/material.dart';
import 'package:flutter_3/models/robot.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RobotsMapView extends StatefulWidget {
  final MQTTClientWrapper mqttClient;
  final List<Robot> robots;

  const RobotsMapView({required this.mqttClient, required this.robots});

  @override
  State<RobotsMapView> createState() => _RobotsMapViewState();
}

class _RobotsMapViewState extends State<RobotsMapView> {
  List<Marker> _markers = [];
LatLngBounds _bounds = LatLngBounds(
  LatLng(0, 0), // First corner (e.g., (0, 0))
  LatLng(0, 0), // Second corner (e.g., (0, 0))
);
  @override
  void initState() {
    super.initState();
    _subscribeToTopics();
  }

  void _subscribeToTopics() {
    widget.robots.forEach((robot) {
      String mqttTopic = '${robot.id}/gps';
      widget.mqttClient.subscribeToTopic(mqttTopic);
    });
  }

  void _updateMarkers(String robotId, Map<String, dynamic> gpsData) {
    if (gpsData.containsKey('lat') && gpsData.containsKey('long')) {
      double lat = gpsData['lat'];
      double long = gpsData['long'];
      LatLng position = LatLng(lat, long);
      _markers.removeWhere((marker) => marker.point == position);

      _markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: position,
          child: const Icon(
            Icons.location_pin,
            color: Colors.blue, // You can customize marker color here
            size: 40.0,
          ),
        ),
      );

      _bounds.extend(position);

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: const Color(0xff121417),
        child: FlutterMap(
          options: MapOptions(
            bounds:  _bounds,
            boundsOptions: const FitBoundsOptions(padding: EdgeInsets.all(20.0)),
            center: LatLng(0.0, 0.0),
            zoom: 5.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            MarkerLayer(markers: _markers),
          ],
        ),
      ),
    );
  }
}
