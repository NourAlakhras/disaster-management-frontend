import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart'; // Import the MQTTClientWrapper

class MonitoringView extends StatefulWidget {
  final String robotId;
  final String mqttTopic;
  final MQTTClientWrapper mqttClient;
  final Map<String, dynamic> receivedData; // Declare receivedData as a parameter

  const MonitoringView({
    Key? key,
    required this.robotId,
    required this.mqttTopic,
    required this.mqttClient,
    required this.receivedData, // Update constructor
  }) : super(key: key);

  @override
  _MonitoringViewState createState() => _MonitoringViewState();
}

class _MonitoringViewState extends State<MonitoringView> {
  late LatLng _robotLocation;
  final Map<String, IconData> iconMap = {
    'Location': Icons.location_on,
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
  void initState() {
    super.initState();
    _robotLocation = LatLng(0.0, 0.0); // Initialize with default values
    updateRobotLocation(widget.receivedData); // Update location with initial data
  }

  @override
  void didUpdateWidget(MonitoringView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.receivedData != widget.receivedData) {
      setState(() {
        _robotLocation = LatLng(0.0, 0.0); // Reset location
      });
      updateRobotLocation(widget.receivedData); // Update location with new data
    }
  }

  void updateRobotLocation(Map<String, dynamic> data) {
    if (data.containsKey('Location')) {
      final locationData = data['Location'].toString().split(',');
      final latitude = double.tryParse(locationData[0]) ?? 0.0;
      final longitude = double.tryParse(locationData[1]) ?? 0.0;
      setState(() {
        _robotLocation = LatLng(latitude, longitude);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: allKeys.length,
      itemBuilder: (context, index) {
        final key = allKeys[index];
        final value = widget.receivedData.isEmpty
            ? 'No data'
            : widget.receivedData.containsKey(key.toLowerCase())
                ? widget.receivedData[key.toLowerCase()].toString()
                : 'No value';
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
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        center: _robotLocation,
                        zoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 80.0,
                              height: 80.0,
                              point: _robotLocation,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
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
}
