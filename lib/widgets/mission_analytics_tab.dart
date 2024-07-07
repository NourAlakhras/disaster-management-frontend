import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_3/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  int _currentSensorIndex = 0; // Track current sensor index

  // Define sensor types in the order you want to display
  List<String> _sensorTypes = [
    'Temperature',
    'Humidity',
    'Distance',
    'Gas Concentration',
    'Air Quality',
    'Smoke Detection',
    'Earthquake Detection',
    'Radiation Level',
    'Light',
    'Sound Level',
  ];

  // Method to update current sensor index
  void _updateCurrentSensorIndex(int newIndex) {
    setState(() {
      _currentSensorIndex = newIndex;
    });
  }

  // Method to go to next sensor
  void _nextSensor() {
    if (_currentSensorIndex < _sensorTypes.length - 1) {
      _updateCurrentSensorIndex(_currentSensorIndex + 1);
    }
  }

  // Method to go to previous sensor
  void _prevSensor() {
    if (_currentSensorIndex > 0) {
      _updateCurrentSensorIndex(_currentSensorIndex - 1);
    }
  }
  final Map<String, Map<String, double>> _deviceSensorData = {};
  late final List<String> topics;
  Map<String, Map<String, double>> thresholds = {};

  @override
  void initState() {
    super.initState();
    topics = widget.devices
        .map((device) =>
            'cloud/reg/${device.broker?.name ?? 'default'}/${device.name ?? 'default'}/sensor_data')
        .toList();
    _subscribeToSensorData(topics);
    _loadThresholds();
  }

  Future<void> _loadThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultThresholds = {
      'temperature': {'low': 0.0, 'high': 30.0},
      'humidity': {'low': 30.0, 'high': 70.0},
      'gas concentration': {'low': 0.0, 'high': 50.0},
      'air quality': {'low': 0.0, 'high': 100.0},
      'smoke detection': {'low': 0.0, 'high': 1.0},
      'earthquake detection': {'low': 0.0, 'high': 1.0},
      'radiation level': {'low': 0.0, 'high': 100.0},
      'sound level': {'low': 0.0, 'high': 70.0},
      'distance': {'low': 0.0, 'high': 100.0},
      'light': {'low': 0.0, 'high': 1000.0},
    };

    setState(() {
      defaultThresholds.forEach((key, value) {
        final low = prefs.getDouble('${key}_low') ?? value['low']!;
        final high = prefs.getDouble('${key}_high') ?? value['high']!;
        thresholds[key] = {'low': low, 'high': high};
      });
    });
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
      if (data.containsKey('gas concentration')) {
        _deviceSensorData[deviceName]!['gas concentration'] =
            data['gas concentration'];
      }
      if (data.containsKey('light')) {
        _deviceSensorData[deviceName]!['light'] = data['light'];
      }
      if (data.containsKey('air quality')) {
        _deviceSensorData[deviceName]!['air quality'] = data['air quality'];
      }
      if (data.containsKey('smoke detection')) {
        _deviceSensorData[deviceName]!['smoke detection'] =
            data['smoke detection'];
      }
      if (data.containsKey('earthquake detection')) {
        _deviceSensorData[deviceName]!['earthquake detection'] =
            data['earthquake detection'];
      }
      if (data.containsKey('sound level')) {
        _deviceSensorData[deviceName]!['sound level'] = data['sound level'];
      }
      if (data.containsKey('radiation level')) {
        _deviceSensorData[deviceName]!['radiation level'] =
            data['radiation level'];
      }
      // Add handling for other sensor types similarly
    });
  }

  Color _generateColor(int index) {
    final double hue =
        (index * 137.508) % 360; // Use golden angle approximation
    return HSVColor.fromAHSV(1.0, hue, 0.5, 0.9).toColor();
  }

  List<BarChartGroupData> _createBarChartData(String sensorType) {
    List<BarChartGroupData> barGroups = [];

    widget.devices.asMap().forEach((index, device) {
      String deviceName = device.name ?? 'Unknown';
      double sensorValue = _deviceSensorData[deviceName]?[sensorType] ?? 0.0;
      Color colorOfBar = _generateColor(index); // Generate color based on index
      barGroups.add(BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            fromY: 0,
            toY: sensorValue,
            color: colorOfBar,
          ),
        ],
      ));
    });

    return barGroups;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(10.0),
      children: [
        _buildSensorBarChart('Temperature', _createBarChartData('temperature')),
        _buildSensorBarChart('Humidity', _createBarChartData('humidity')),
        _buildSensorBarChart('Distance', _createBarChartData('distance')),
        _buildSensorBarChart(
            'Gas Concentration', _createBarChartData('gas concentration')),
        _buildSensorBarChart('Air Quality', _createBarChartData('air quality')),
        _buildSensorBarChart(
            'Smoke Detection', _createBarChartData('smoke detection')),
        _buildSensorBarChart('Earthquake Detection',
            _createBarChartData('earthquake detection')),
        _buildSensorBarChart(
            'Radiation Level', _createBarChartData('radiation level')),
        _buildSensorBarChart('Light', _createBarChartData('light')),
        _buildSensorBarChart('Sound Level', _createBarChartData('sound level')),
        // Add more charts for other sensor types similarly
      ],
    );
  }

  Widget _buildSensorBarChart(
      String title, List<BarChartGroupData> barChartData) {
    double minY = thresholds[title.toLowerCase()]?['low'] ?? 0.0;
    double maxY = thresholds[title.toLowerCase()]?['high'] ?? 100.0;

    // Define labels for the thresholds
    String minLabel = 'Min: $minY';
    String maxLabel = 'Max: $maxY';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              title,
              style: const TextStyle(
                color: accentColor,
                fontSize: 20,
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: secondaryTextColor, // Choose your border color here
                  width: 0.1, // Adjust the border thickness
                ),
              ),
            ),
            height: 300, // Adjust height as needed
            padding: const EdgeInsets.fromLTRB(3, 0, 3, 20),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                backgroundColor: Colors.transparent,
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
                            color:
                                secondaryTextColor, // Set your desired color here
                            fontWeight: FontWeight.normal,
                          ),
                        );
                      },
                      reservedSize: 40, // Adjust the margin value as needed
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        if (value == minY) {
                          return Text(minLabel);
                        } else if (value == maxY) {
                          return Text(maxLabel);
                        } else {
                          return const Text('');
                        }
                      },
                      interval: (maxY - minY) /
                          2, // Adjust interval based on your data range                      reservedSize: 40, // Adjust the margin value as needed
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
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: minY,
                      color: Colors.green,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        alignment: Alignment.topRight,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                        labelResolver: (_) => 'low: $minY',
                        show: true,
                      ),
                    ),
                    HorizontalLine(
                      y: maxY,
                      color: Colors.red,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        alignment: Alignment.topRight,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                        labelResolver: (_) => 'high: $maxY',
                        show: true,
                      ),
                    ),
                  ],
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
