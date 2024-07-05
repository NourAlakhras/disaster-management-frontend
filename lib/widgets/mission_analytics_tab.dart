import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_3/utils/app_colors.dart';

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
    topics = widget.devices
        .map((device) =>
            'cloud/reg/${device.broker?.name ?? 'default'}/${device.name ?? 'default'}/sensor_data')
        .toList();
    _subscribeToSensorData(topics);
  }

  void _subscribeToSensorData(List<String> topics) {
    widget.mqttClient.subscribeToMultipleTopics(topics);
    widget.mqttClient.onDataReceived = _onDataReceived;
  }

  void _onDataReceived(Map<String, dynamic> data) {
    setState(() {
      // Extract device name from topic
      String topic = data['topic'];
      String deviceName = topic.split('/')[3]; // Get "Device16" from the topic

      // Initialize sensor data map for this device if not already present
      _deviceSensorData.putIfAbsent(deviceName, () => {});

      // Update each sensor type's value for this device
      if (data.containsKey('temperature')) {
        _deviceSensorData[deviceName]!['temperature'] = data['temperature'];
      }
      if (data.containsKey('humidity')) {
        _deviceSensorData[deviceName]!['humidity'] = data['humidity'];
      }
      if (data.containsKey('distance')) {
        _deviceSensorData[deviceName]!['distance'] = data['distance'];
      }
      if (data.containsKey('light')) {
        _deviceSensorData[deviceName]!['light'] = data['light'];
      }

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
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSensorBarChart('Temperature', _createBarChartData('temperature')),
        _buildSensorBarChart('Humidity', _createBarChartData('humidity')),
        _buildSensorBarChart('Distance', _createBarChartData('distance')),
        _buildSensorBarChart('Light', _createBarChartData('light')),
        // Add more charts for other sensor types similarly
      ],
    );
  }

  Widget _buildSensorBarChart(
      String title, List<BarChartGroupData> barChartData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: accentColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Container(
              // decoration: BoxDecoration(
              //   gradient: LinearGradient(
              //     colors: [cardColor, barColor],
              //     begin: Alignment.topLeft,
              //     end: Alignment.bottomRight,
              //   ),
              //   borderRadius: BorderRadius.circular(8.0),
              // ),
              height: 400, // Adjust height as needed
              padding: const EdgeInsets.all(10.0),
               child: BarChart(
              BarChartData(
                backgroundColor: Colors.transparent,
                minY: 0,
                maxY: 500,
                barGroups: barChartData,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        return Text(
                          widget.devices[value.toInt()].name,
                          style: const TextStyle(
                            color: secondaryTextColor,
                            fontWeight: FontWeight.normal,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: secondaryTextColor, // Set your desired color here
                            fontWeight: FontWeight.normal,
                          ),
                        );
                      },
                      reservedSize: 40, // Adjust the margin value as needed
                    ),
                  ),
                ),
                  
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final deviceName = widget.devices[group.x.toInt()].name;
                        return BarTooltipItem(
                          textAlign: TextAlign.left,
                          '$deviceName\n',
                          const TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: '${rod.toY}',
                              style: const TextStyle(
                                color: barColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                      getTooltipColor: (group) => secondaryTextColor,
                      fitInsideHorizontally: true,
                      fitInsideVertically: false,
                      direction: TooltipDirection.auto,
                    ),
                  ),
                ),
              ),
            ),
          
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.mqttClient.unsubscribeFromMultipleTopics(topics);
    super.dispose();
  }
}
