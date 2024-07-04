import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/services/mission_api_service.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_search_bar.dart';
import 'package:flutter_3/widgets/filter_drawer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' show Random, atan2, cos, log, pi, sin, sqrt;
import 'package:flutter_3/utils/app_colors.dart';

class DevicesMapView extends StatefulWidget {
  final MQTTClientWrapper mqttClient;

  const DevicesMapView({super.key, required this.mqttClient});

  @override
  State<DevicesMapView> createState() => _DevicesMapViewState();
}

class _DevicesMapViewState extends State<DevicesMapView> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  LatLngBounds _bounds = LatLngBounds(
    southwest: const LatLng(0, 0), // First corner (e.g., (0, 0))
    northeast: const LatLng(0, 0), // Second corner (e.g., (0, 0))
  );
  List<Device> _filteredDevices = [];
  List<Mission> _filteredMissions = [];
  bool _isLoading = false;
  int _pageNumber = 1;
  final int _pageSize = 10000;
  final TextEditingController _searchController = TextEditingController();
  final List<MissionStatus> _filteredStatuses = [
    MissionStatus.ONGOING,
  ];
  List<DeviceType>? _filteredTypes = DeviceType.values;
  String? _name;
  final criteriaList = [
    FilterCriterion(name: 'Device Type', options: DeviceType.values.toList()),
  ]; // Map to store mission IDs and corresponding colors
  final Map<String, Color> _missionColorMap = {};
  @override
  void initState() {
    super.initState();
    _fetchMissions();
    widget.mqttClient.onDataReceived = _onDataReceived;
    _subscribeToTopics();
    widget.mqttClient.setupMessageListener();
  }

  Future<void> _fetchMissions({
    List<MissionStatus>? statuses,
    int? pageNumber,
    int? pageSize,
    String? name,
  }) async {
    // Assign default statuses if not provided
    statuses ??= _filteredStatuses;
    pageNumber ??= _pageNumber;
    pageSize ??= _pageSize;
    name ??= _name;
    setState(() {
      _isLoading = true;
    });
    try {
      final missionResponse = await MissionApiService.getAllMissions(
        pageNumber: _pageNumber,
        pageSize: _pageSize,
        statuses: statuses,
        name: name,
      );
      setState(() {
        _filteredMissions = missionResponse.items;
      });
      print('_filteredMissions $_filteredMissions');

      for (var mission in _filteredMissions) {
        await mission.fetchMissionDetails(() {
          if (mounted) {
            setState(() {});
          }
        });
        await mission.fetchDetailedDeviceInfo();
      }
// Generate colors for missions and store them in the mission-color map
      for (var mission in _filteredMissions) {
        // Generate a random color
        Color missionColor = _generateRandomColor();

        // Store the mission ID and its color in the map
        _missionColorMap[mission.id] = missionColor;
      }
      setState(() {
        _filteredDevices = _filteredMissions
            .expand((mission) => mission.devices ?? [])
            .cast<Device>()
            .where((device) => _filteredTypes!.contains(device.type))
            .toList();
      });
      print('_filteredDevices $_filteredDevices');
    } catch (error) {
      print('Failed to fetch missions: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _generateRandomColor() {
    final Random random = Random();
    return Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1,
    );
  }

  void _subscribeToTopics() {
    for (var device in _filteredDevices) {
      String mqttTopic = '${device.device_id}/gps';
      widget.mqttClient.subscribeToTopic(mqttTopic);
    }

    // widget.mqttClient.subscribeToMultipleTopics([
    //   'test-ugv/sensor_data',
    //   "test-ugv1/gps",
    //   "test-ugv0/gps",
    //   "test-ugv2/gps"
    // ]);
  }

  void _onDataReceived(Map<String, dynamic> message) {
    String deviceId =
        message['topic'].substring(0, message['topic'].length - 4);
    print('from map this is my topic $deviceId');
    _updateMarkers(deviceId, message);
  }

  void _updateMarkers(String deviceId, Map<String, dynamic> gpsData) {
    if (gpsData.containsKey('lat') && gpsData.containsKey('long')) {
      double lat = gpsData['lat'];
      double long = gpsData['long'];
      LatLng position = LatLng(lat, long);
      _markers.removeWhere((marker) => marker.markerId.value == deviceId);
      String missionId = _getMissionIdFromDevice(deviceId);
      Color missionColor = _missionColorMap[missionId] ?? Colors.blue;

      // Find the device by its ID from the _filteredDevices list
      Device device = _filteredDevices.firstWhere(
        (device) => device.device_id == deviceId,
        orElse: () => Device(
            device_id: deviceId,
            name: 'Unknown Device',
            type: DeviceType.UGV, // or any default type
            status: DeviceStatus.AVAILABLE // or any default status
            ),
      );

      // If the device is found, use its name; otherwise, use a default name
      String deviceName = device.name;

      // Add marker with custom color
      _markers.add(
        Marker(
          markerId: MarkerId(deviceId),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getColorHue(missionColor),
          ),
          infoWindow: InfoWindow(title: deviceName),
        ),
      );

      _adjustBounds(position);

      // Update camera position to show all markers
      _fitBounds();

      setState(() {});
    }
  }

// Get the mission ID associated with the device ID
  String _getMissionIdFromDevice(String deviceId) {
    for (var mission in _filteredMissions) {
      for (var device in mission.devices!) {
        if (device.device_id == deviceId) {
          return mission.id;
        }
      }
    }
    return ''; // Return empty string if no mission ID found
  }

  double _getColorHue(Color color) {
    // Calculate hue from color
    HSVColor hsvColor = HSVColor.fromColor(color);
    return hsvColor.hue;
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
    if (_markers.isNotEmpty) {
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
    return Scaffold(
      body: Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15.0, 00),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                child: CustomSearchBar(
                  controller: _searchController,
                  onChanged: _filterDevices,
                  onClear: _clearSearch,
                ),
              ),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_filteredDevices.isEmpty)
                const Center(
                  child: Text(
                    'No devices available',
                    style: TextStyle(color: primaryTextColor),
                  ),
                )
              else
                Expanded(
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
                )),
            ],
          )),
      endDrawer: FilterDrawerWidget(
        onFilterApplied: (selectedCriteria) {
          final List<DeviceType> selectedTypes =
              (selectedCriteria['Device Type'] as List<dynamic>)
                  .cast<DeviceType>();

          setState(() {
            _filteredTypes =
                selectedTypes.isNotEmpty ? selectedTypes : DeviceType.values;
            _pageNumber = 1;
          });

          _fetchMissions();
        },
        criteriaList: criteriaList,
        title: 'Filter Options',
      ),
    );
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

  void _filterDevices(String name) {
    if (name.isNotEmpty) {
      // Call fetch devices with the search query
      setState(() {
        _name = name;
      });
    } else {
      // If query is empty, fetch all devices
      _fetchMissions();
    }

    setState(() {
      _pageNumber = 1;
    });
    _fetchMissions();
  }

  void _clearSearch() {
    // Clear the search query
    _searchController.clear();
    setState(() {
      _name = '';
      _pageNumber = 1;
    });
    _fetchMissions();

    // Call filterDevices with an empty string to reset the filtered list
    _filterDevices('');
  }
}
