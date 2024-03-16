import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart'; 

class MonitoringView extends StatefulWidget {
  final String robotId;
  final MQTTClientWrapper mqttClient;

  const MonitoringView({
    Key? key,
    required this.robotId,
    required this.mqttClient,
  }) : super(key: key);

  @override
  _MonitoringViewState createState() => _MonitoringViewState();
}

class _MonitoringViewState extends State<MonitoringView> {
  late LatLng _robotLocation;
  late double _batteryLevel;
  late double _wifiLevel;
  late Map<String, dynamic> _sensorData;

  @override
  void initState() {
    super.initState();
    _robotLocation = LatLng(0.0, 0.0);
    _batteryLevel = 0.0;
    _wifiLevel = 0.0;
    _sensorData = {};

    widget.mqttClient.onDataReceived = onDataReceived;
    widget.mqttClient.subscribeToMultipleTopics([
      'test-ugv/sensor_data',
      '${widget.robotId}/gps',
      '${widget.robotId}/sensor_data',
      '${widget.robotId}/connectivity',
      '${widget.robotId}/battery',
    ]);
    // widget.mqttClient.setupMessageListener(); 
  }

  void onDataReceived(Map<String, dynamic> data) {
  if (data.containsKey('lat') && data.containsKey('long')) {
    final latitude = data['lat'] ?? 0.0;
    final longitude = data['long'] ?? 0.0;
    setState(() {
      _robotLocation = LatLng(latitude, longitude);
    });
  } else if (data.containsKey('wifi')) {
    final wifiLevel = data['wifi'] ?? 0.0;
    setState(() {
      _wifiLevel = wifiLevel;
    });
  } else if (data.containsKey('battery')) {
    final batteryLevel = data['battery'] ?? 0.0;
    setState(() {
      _batteryLevel = batteryLevel;
    });
  } else {
    // Handle other sensor data here
    data.forEach((key, value) {
      setState(() {
      _sensorData[key] = value;});
    });
  }
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
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: _robotLocation,
                        initialZoom: 15.0,
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
    

  @override
  void dispose() {
    widget.mqttClient.unsubscribeFromMultipleTopics([
      '${widget.robotId}/gps',
      '${widget.robotId}/sensor_data',
      '${widget.robotId}/connectivity',
      '${widget.robotId}/battery',
    ]);
    super.dispose();
}
}