import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/gps_data.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:flutter_3/providers/sensor_data_provider.dart';

class MissionDevicesMapTab extends StatefulWidget {
  final List<Device> devices;
  final Device? broker;

  const MissionDevicesMapTab({
    super.key,
    required this.devices,
    required this.broker,
  });

  @override
  State<MissionDevicesMapTab> createState() => _MissionDevicesMapTabState();
}

class _MissionDevicesMapTabState extends State<MissionDevicesMapTab> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLngBounds _bounds = LatLngBounds(
    southwest: const LatLng(0, 0),
    northeast: const LatLng(0, 0),
  );

  @override
  void initState() {
    super.initState();
    print(
        'MissionDevicesMapTab initialized with ${widget.devices.length} devices and broker ${widget.broker}');
  }
void _updateMarkers(String deviceName, GPSData gpsData) {
    String cleanedDeviceName = deviceName.replaceAll('/gps', '');
    print('Updating markers for device: $cleanedDeviceName');

    double lat = gpsData.lat ?? 0.0;
    double long = gpsData.long ?? 0.0;
    LatLng position = LatLng(lat, long);
    print('Received GPS data for $cleanedDeviceName: lat=$lat, long=$long');

    // Remove existing marker for the device
    _markers
        .removeWhere((marker) => marker.markerId.value == cleanedDeviceName);

    // Get marker color based on the device's name
    int deviceIndex =
        widget.devices.indexWhere((device) => device.name == cleanedDeviceName);
    if (deviceIndex == -1) {
      print('Device $cleanedDeviceName not found in the list');
      return; // Exit if device is not found
    }

    Color color = _generateColor(deviceIndex);
    print('Generated color for $cleanedDeviceName: $color');

    _markers.add(
      Marker(
        markerId: MarkerId(cleanedDeviceName),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(_getColorHue(color)),
        infoWindow: InfoWindow(title: cleanedDeviceName),
      ),
    );
    print('Added new marker for $cleanedDeviceName at position: $position');

    _adjustBounds(position);
    print('Adjusted bounds with position: $position');

    // Schedule to fit bounds after the build is completed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapController != null) {
        _fitBounds();
      } else {
        print('Map controller not yet initialized when fitting bounds');
      }
    });
  }


  Color _generateColor(int index) {
    final double hue = (index * 137.508) % 360;
    print('Generating color for index $index: hue=$hue');
    return HSVColor.fromAHSV(1.0, hue, 0.5, 0.9).toColor();
  }

  double _getColorHue(Color color) {
    double hue = HSVColor.fromColor(color).hue;
    print('Extracted hue $hue from color $color');
    return hue;
  }

  void _adjustBounds(LatLng position) {
    double minLat = _bounds.southwest.latitude;
    double minLong = _bounds.southwest.longitude;
    double maxLat = _bounds.northeast.latitude;
    double maxLong = _bounds.northeast.longitude;

    minLat = min(minLat, position.latitude);
    minLong = min(minLong, position.longitude);
    maxLat = max(maxLat, position.latitude);
    maxLong = max(maxLong, position.longitude);

    _bounds = LatLngBounds(
      southwest: LatLng(minLat, minLong),
      northeast: LatLng(maxLat, maxLong),
    );

    print(
        'Updated map bounds: Southwest: $minLat, $minLong; Northeast: $maxLat, $maxLong');
  }

  void _fitBounds() {
    if (_mapController != null && _markers.isNotEmpty) {
      LatLngBounds bounds = _bounds;
      LatLng centerPoint = _calculateCenterPoint(
          _markers.map((marker) => marker.position).toList());
      print('Calculated center point: $centerPoint');

      double zoomLevel = _calculateZoomLevel(bounds, centerPoint);
      print('Calculated zoom level: $zoomLevel');

      _mapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: centerPoint,
          zoom: zoomLevel,
        ),
      ));
      print(
          'Animated camera to center point: $centerPoint with zoom level: $zoomLevel');
    } else {
      print(
          'No markers available or map controller not initialized to fit bounds');
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

    LatLng center = LatLng(lat * 180 / pi, lon * 180 / pi);
    print('Calculated center point from positions: $center');
    return center;
  }

  double _calculateZoomLevel(LatLngBounds bounds, LatLng center) {
    const double maxZoom = 0.0;
    const double minZoom = 0.0;
    const double padding = 0.0;

    double angle = _calculateAngleFromCenter(bounds, center);
    double cameraSize = _calculateCameraSize(bounds, center);
    double scale = MediaQuery.of(context).devicePixelRatio;

    double zoom = maxZoom -
        (log(angle) / log(2)) +
        (log(cameraSize / (256 * scale * padding)) / log(2));
    zoom = zoom.clamp(minZoom, maxZoom);

    print(
        'Calculated zoom level: $zoom (angle: $angle, camera size: $cameraSize, scale: $scale)');
    return zoom;
  }

  double _calculateAngleFromCenter(LatLngBounds bounds, LatLng center) {
    LatLng northeast = bounds.northeast;
    LatLng southwest = bounds.southwest;

    double angle = _distanceBetweenLatLng(northeast, southwest);
    print('Calculated angle from center: $angle');
    return angle;
  }

  double _calculateCameraSize(LatLngBounds bounds, LatLng center) {
    double cameraSize =
        _distanceBetweenLatLng(bounds.northeast, bounds.southwest);
    print('Calculated camera size: $cameraSize');
    return cameraSize;
  }

  double _distanceBetweenLatLng(LatLng latLng1, LatLng latLng2) {
    const double radius = 6371e3; // Earth radius in meters

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
    print(
        'Calculated distance between $latLng1 and $latLng2: $distance meters');
    return distance;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorDataProvider>(
      builder: (context, sensorDataProvider, child) {
        print(
            'Building widget with sensor data: ${sensorDataProvider.gpsData}');

        // Update markers based on GPS data
        sensorDataProvider.gpsData.forEach((deviceName, gpsData) {
          print('Processing GPS data for device: $deviceName');
          _updateMarkers(deviceName, gpsData);
        });

        return Scaffold(
          body: GoogleMap(
            gestureRecognizers: {
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
              Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
              Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer()),
              Factory<HorizontalDragGestureRecognizer>(
                  () => HorizontalDragGestureRecognizer()),
              Factory<LongPressGestureRecognizer>(
                  () => LongPressGestureRecognizer()),
            },
            compassEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
              print('Map controller created: $_mapController');
              // Fit bounds after the map is created
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fitBounds();
              });
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(0.0, 0.0),
              zoom: 10,
            ),
            markers: _markers,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    print('MissionDevicesMapTab disposed');
  }
}
