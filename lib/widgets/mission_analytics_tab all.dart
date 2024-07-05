import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:fl_chart/fl_chart.dart';

class MissionAnalyticsTabAll extends StatefulWidget {
  final MQTTClientWrapper mqttClient;
  final List<Device> devices;

  const MissionAnalyticsTabAll({
    Key? key,
    required this.mqttClient,
    required this.devices,
  }) : super(key: key);

  @override
  State<MissionAnalyticsTabAll> createState() => _MissionAnalyticsTabAllState();
}

class _MissionAnalyticsTabAllState extends State<MissionAnalyticsTabAll> {
  final Map<String, double> _sensorData = {
    'temperature': 0.0,
    'humidity': 0.0,
    'gas concentration': 0.0,
    'air quality': 0.0,
    'smoke detection': 0.0,
    'earthquake detection': 0.0,
    'radiation level': 0.0,
    'sound level': 0.0,
    'light': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _subscribeToSensorData();
  }

  void _subscribeToSensorData() {
    final topics = [
      ...widget.devices.map((device) =>
          'cloud/reg/${device.broker?.name ?? 'default'}/${device.name ?? 'default'}/sensor_data'),
      'test-ugv/sensor_data', // Adding 'test-ugv/sensor_data' topic
    ];

    widget.mqttClient.subscribeToMultipleTopics(topics);
    widget.mqttClient.onDataReceived = _onDataReceived;
  }

  void _onDataReceived(Map<String, dynamic> data) {
    print('Received data:');
    print(data);
    // Update sensor data if received
    data.forEach((key, value) {
      if (value is double) {
        setState(() {
          _sensorData[key.toLowerCase()] = value;
        });
      } else {
        print('Received non-double value for sensor type $key: $value');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    
      body: ListView(
        children: _sensorData.keys.map((sensorType) {
          return _buildSensorChart(sensorType);
        }).toList(),
      ),
    );
  }

  Widget _buildSensorChart(String sensorType) {
    final double value = _sensorData[sensorType.toLowerCase()] ?? 0.0;

    // Get the index of the current sensor type
    int index = _sensorData.keys.toList().indexOf(sensorType.toLowerCase());

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              sensorType,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            height: 200,
            padding: const EdgeInsets.all(8.0),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                barGroups: [
                  BarChartGroupData(
                    x: 0, // Fixed x value for the single bar group
                    barRods: [
                      BarChartRodData(
                        fromY: 0.0,
                        toY: value+100,
                        color: Colors.amber,
                        width: 15,
                      ),
                    ],
                  ),
                ],
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, _) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        );
                      },
                  ),),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, _) {
                        int intValue = value.toInt();
                        if (intValue >= 0 && intValue < widget.devices.length) {
                          return Text(
                            widget.devices[intValue].name,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                  ),),
                  topTitles: AxisTitles(sideTitles: SideTitles( showTitles: false),),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false),),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
