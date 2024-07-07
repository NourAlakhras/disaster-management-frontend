import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:fl_chart/fl_chart.dart';

class MissionAnalyticsTab extends StatefulWidget {
  final MQTTClientWrapper mqttClient;
  final List<Device> devices;

  const MissionAnalyticsTab({
    Key? key,
    required this.mqttClient,
    required this.devices,
  }) : super(key: key);

  @override
  State<MissionAnalyticsTab> createState() => _MissionAnalyticsTabState();
}

class _MissionAnalyticsTabState extends State<MissionAnalyticsTab> {
  final Map<String, Map<String, double>> _deviceSensorData = {};
  late final List<String> topics;
  @override
  void initState() {
    super.initState();
    final topics = widget.devices.map((device) =>
        'cloud/reg/${device.broker?.name ?? 'default'}/${device.name ?? 'default'}/sensor-data');
    _subscribeToSensorData(topics);
  }

  void _subscribeToSensorData(topics) {
    widget.mqttClient.subscribeToMultipleTopics(topics.toList());
    widget.mqttClient.onDataReceived = _onDataReceived;
  }

  void _onDataReceived(Map<String, dynamic> data) {
    setState(() {
      // Extract device name from topic
      String topic = data['topic'];
      String deviceName = topic.split('/').last;

      // Initialize sensor data map for this device if not already present
      _deviceSensorData.putIfAbsent(deviceName, () => {});

      // Update each sensor type's value for this device
      _deviceSensorData[deviceName]!['temperature'] = data['temperature'];
      _deviceSensorData[deviceName]!['humidity'] = data['humidity'];
      _deviceSensorData[deviceName]!['distance'] = data['distance'];
      _deviceSensorData[deviceName]!['light'] = data['light'];

      // Add handling for other sensor types similarly
    });
  }

  List<BarChartGroupData> _createBarChartData(String sensorType) {
    List<BarChartGroupData> barGroups = [];

    widget.devices.forEach((device) {
      String deviceName = device.name ?? 'Unknown';
      double sensorValue = _deviceSensorData[deviceName]?[sensorType] ?? 0.0;

      barGroups.add(BarChartGroupData(
        x: widget.devices.indexOf(device),
        barRods: [
          BarChartRodData(
            fromY: 0,
            toY: sensorValue,
            color: Colors.blue, // Customize colors as needed
          ),
        ],
      ));
    });

    return barGroups;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Example for Temperature bar chart
        _buildSensorBarChart('Temperature', _createBarChartData('temperature')),
        // Add more charts for other sensor types similarly
      ],
    );
  }

  Widget _buildSensorBarChart(
      String title, List<BarChartGroupData> barChartData) {
    print('barChartData $barChartData');
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Card(
          margin: const EdgeInsets.all(8.0),
          child: Container(
            height: 200,
            padding: const EdgeInsets.all(8.0),
            child: BarChart(
              BarChartData(
                barGroups: barChartData,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          return Text(
                              widget.devices[value.toInt()].name ?? 'Unknown');
                        }),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true)),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    widget.mqttClient.unsubscribeFromMultipleTopics(topics);
    super.dispose();
  }
}
