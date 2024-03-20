import 'package:flutter/material.dart';
import 'package:flutter_3/models/robot.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' show atan2, cos, pi, sin, sqrt, log;

class RobotsMapView extends StatefulWidget {
  final MQTTClientWrapper mqttClient;
  final List<Robot> robots;

  const RobotsMapView({required this.mqttClient, required this.robots});

  @override
  State<RobotsMapView> createState() => _RobotsMapViewState();
}

class _RobotsMapViewState extends State<RobotsMapView> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  LatLngBounds _bounds = LatLngBounds(
    southwest: const LatLng(0, 0), // First corner (e.g., (0, 0))
    northeast: const LatLng(0, 0), // Second corner (e.g., (0, 0))
  );

  @override
  void initState() {
    super.initState();
    widget.mqttClient.onDataReceived = _onDataReceived;
    _subscribeToTopics();
    widget.mqttClient.setupMessageListener();
  }

  void _subscribeToTopics() {
    widget.robots.forEach((robot) {
      String mqttTopic = '${robot.id}/gps';
      widget.mqttClient.subscribeToTopic(mqttTopic);
    });

    widget.mqttClient.subscribeToMultipleTopics([
      'test-ugv/sensor_data',
      "test-ugv1/gps",
      "test-ugv0/gps",
      "test-ugv2/gps"
    ]);
  }

  void _onDataReceived(Map<String, dynamic> message) {
    String robotId = message['topic'].substring(0, message['topic'].length - 4);
    print('from map this is my topic $robotId');
    _updateMarkers(robotId, message);
  }

  void _updateMarkers(String robotId, Map<String, dynamic> gpsData) {
    if (gpsData.containsKey('lat') && gpsData.containsKey('long')) {
      double lat = gpsData['lat'];
      double long = gpsData['long'];
      LatLng position = LatLng(lat, long);
      _markers.removeWhere((marker) => marker.markerId.value == robotId);

      // Get marker color based on the robot's ID
      Color color = _getMarkerColor(robotId);
      String robotName = _getRobotName(robotId); // Get the robot's name

      // Add marker with custom color
      _markers.add(
        Marker(
          markerId: MarkerId(robotId),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getColorHue(color),
          ),
          infoWindow: InfoWindow(title: robotId), // Set the info window
        ),
      );

      _adjustBounds(position);

      // Update camera position to show all markers
      _fitBounds();

      setState(() {});
    }
  }

  // Define a list of colors to use for markers
  final List<Color> _markerColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    // Add more colors as needed
  ];

  Color _getMarkerColor(String robotId) {
    // Choose a color based on the modified robot's ID
    int index = robotId.hashCode % _markerColors.length;
    return _markerColors[index];
  }

  double _getColorHue(Color color) {
    // Calculate hue from color
    HSVColor hsvColor = HSVColor.fromColor(color);
    return hsvColor.hue;
  }

  String _getRobotName(String robotId) {
    // Find the robot object by its ID and return its name
    Robot? robot = widget.robots.firstWhere((robot) => robot.id == robotId,
        orElse: () => Robot(id: robotId, name: 'Unknown'));
    return robot.name;
  }

  void _adjustBounds(LatLng position) {
    double minLat = _bounds.southwest.latitude;
    double minLong = _bounds.southwest.longitude;
    double maxLat = _bounds.northeast.latitude;
    double maxLong = _bounds.northeast.longitude;

    if (position.latitude < minLat) minLat = position.latitude;
    if (position.longitude < minLong) minLong = position.longitude;
    if (position.latitude > maxLat) maxLat = position.latitude;
    if (position.longitude > maxLong) maxLong = position.longitude;

    _bounds = LatLngBounds(
      southwest: LatLng(minLat, minLong),
      northeast: LatLng(maxLat, maxLong),
    );
  }

  void _fitBounds() {
    if (_markers.isNotEmpty && _mapController != null) {
      LatLngBounds bounds = _bounds;

      // Calculate center point based on markers
      LatLng centerPoint = _calculateCenterPoint(
          _markers.map((marker) => marker.position).toList());

      // Adjust zoom level to fit all markers
      double zoomLevel = _calculateZoomLevel(bounds, centerPoint);

      _mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: centerPoint,
          zoom: zoomLevel,
        ),
      ));
    }
  }

  LatLng _calculateCenterPoint(List<LatLng> positions) {
    double sumX = 0.0;
    double sumY = 0.0;
    double sumZ = 0.0;

    for (final position in positions) {
      double lat = position.latitude * pi / 180;
      double lon = position.longitude * pi / 180;

      sumX += cos(lat) * cos(lon);
      sumY += cos(lat) * sin(lon);
      sumZ += sin(lat);
    }

    int total = positions.length;

    sumX /= total;
    sumY /= total;
    sumZ /= total;

    double lon = atan2(sumY, sumX);
    double hyp = sqrt(sumX * sumX + sumY * sumY);
    double lat = atan2(sumZ, hyp);

    return LatLng(lat * 180 / pi, lon * 180 / pi);
  }

  double _calculateZoomLevel(LatLngBounds bounds, LatLng center) {
    const double maxZoom = 20.0;
    const double minZoom = 10.0;
    const double padding = 50.0;
    double zoom = minZoom;

    double angle = _calculateAngleFromCenter(bounds, center);

    double cameraSize = _calculateCameraSize(bounds, center);

    double scale = MediaQuery.of(context).devicePixelRatio;

    // Adjust zoom level based on camera size and angle
    zoom = maxZoom -
        (log(angle) / log(2)) +
        (log(cameraSize / (256 * scale * padding)) / log(2));

    return zoom.clamp(minZoom, maxZoom);
  }

  double _calculateAngleFromCenter(LatLngBounds bounds, LatLng center) {
    LatLng northeast = bounds.northeast;
    LatLng southwest = bounds.southwest;

    double angle = _distanceBetweenLatLng(northeast, southwest);

    return angle;
  }

  double _calculateCameraSize(LatLngBounds bounds, LatLng center) {
    double cameraSize =
        _distanceBetweenLatLng(bounds.northeast, bounds.southwest);

    return cameraSize;
  }

  double _distanceBetweenLatLng(LatLng latLng1, LatLng latLng2) {
    const double radius = 6371e3; // Earth's radius in meters

    double lat1 = latLng1.latitude * pi / 180;
    double lon1 = latLng1.longitude * pi / 180;
    double lat2 = latLng2.latitude * pi / 180;
    double lon2 = latLng2.longitude * pi / 180;

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    double distance = radius * c;

    return distance;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Container(
      child: GoogleMap(
        gestureRecognizers: Set()
          ..add(Factory<PanGestureRecognizer>(() => PanGestureRecognizer()))
          ..add(Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()))
          ..add(Factory<TapGestureRecognizer>(() => TapGestureRecognizer()))
          ..add(Factory<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer()))
          ..add(Factory<HorizontalDragGestureRecognizer>(
              () => HorizontalDragGestureRecognizer()))
          ..add(Factory<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer())),

        compassEnabled: true,
        rotateGesturesEnabled: true, // Respond to rotate gestures
        tiltGesturesEnabled: true, // Respond to tilt gestures
        zoomControlsEnabled: true, // Show zoom controls
        zoomGesturesEnabled: true, // Respond to zoom gestures
        onMapCreated: (controller) {
          _mapController = controller;
        },
        initialCameraPosition: const CameraPosition(
          target: LatLng(0.0, 0.0),
          zoom: 50,
        ),
        markers: _markers,
      ),
    ));
  }


  @override
  void dispose() {
    widget.mqttClient.unsubscribeFromMultipleTopics([
      'test-ugv/sensor_data',
      "test-ugv1/gps",
      "test-ugv0/gps",
      "test-ugv2/gps"
    ]);
    super.dispose();
  }

}
