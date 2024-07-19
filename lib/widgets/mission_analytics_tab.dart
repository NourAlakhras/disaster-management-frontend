import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/providers/sensor_data_provider.dart';
import 'package:flutter_3/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MissionAnalyticsTab extends StatefulWidget {
  final List<Device> devices;
  final Device? broker;

  const MissionAnalyticsTab({
    Key? key,
    required this.devices,
    required this.broker,
  }) : super(key: key);

  @override
  State<MissionAnalyticsTab> createState() => _MissionAnalyticsTabState();
}

class _MissionAnalyticsTabState extends State<MissionAnalyticsTab> {
  final deviceSensorData = <String, Map<String, dynamic>>{};
  Map<String, Map<String, double>> thresholds = {};

  @override
  void initState() {
    super.initState();
    _loadThresholds();
  }

  Future<void> _loadThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultThresholds = {
      'temperature': {'low': 0.0, 'high': 30.0},
      'humidity': {'low': 30.0, 'high': 70.0},
      'gas': {'low': 0.0, 'high': 50.0},
      'co2': {'low': 0.0, 'high': 1000.0},
      'tvoc': {'low': 0.0, 'high': 500.0},
      'accelerometer': {'low': -10.0, 'high': 10.0},
      'gyroscope': {'low': -200.0, 'high': 200.0},
      'ir': {'low': 0.0, 'high': 1.0},
      'ultrasonic': {'low': 0.0, 'high': 100.0},
      'sound': {'low': 0.0, 'high': 100.0},
      'battery': {'low': 0.0, 'high': 100.0},
    };

    setState(() {
      defaultThresholds.forEach((key, value) {
        final low = prefs.getDouble('${key}_low') ?? 0.0;
        final high = prefs.getDouble('${key}_high') ?? 100.0;
        thresholds[key] = {'low': low, 'high': high};
      });
    });
  }

  Color _generateColor(int index) {
    final double hue = (index * 137.508) % 360;
    return HSVColor.fromAHSV(1.0, hue, 0.5, 0.9).toColor();
  }

  List<BarChartGroupData> _createBarChartData(String sensorType) {
    print('_createBarChartData sensorType $sensorType');
    List<BarChartGroupData> barGroups = [];

    widget.devices.asMap().forEach((index, device) {
      String deviceName = device.name ?? 'Unknown';
      print('_createBarChartData deviceName $deviceName');
      print('deviceSensorData $deviceSensorData');
      dynamic sensorValue = deviceSensorData[deviceName]?[sensorType]?['value'];

      sensorValue ??= 0.0;
      print('_createBarChartData sensorValue $sensorValue');
      Color colorOfBar = _generateColor(index);
      barGroups.add(BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            fromY: 0,
            toY: sensorValue.toDouble(),
            color: colorOfBar,
            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
        ],
      ));
    });

    return barGroups;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorDataProvider>(
      builder: (context, sensorDataProvider, child) {
        // Collect sensor data from the provider
        sensorDataProvider.sensorData.forEach((key, sensorReading) {
          final deviceName = key.split('/')[0];
          final sensorType = sensorReading.sensor;
          final value = sensorReading.value;
          final unit = sensorReading.unit;

          deviceSensorData.putIfAbsent(deviceName, () => {});
          deviceSensorData[deviceName]![sensorType] = {
            'value': value,
            'unit': unit,
          };
        });
        print('build deviceSensorData $deviceSensorData');
        return ListView(
          padding: const EdgeInsets.all(10.0),
          children: _buildCharts(deviceSensorData),
        );
      },
    );
  }

  List<Widget> _buildCharts(
      Map<String, Map<String, dynamic>> deviceSensorData) {
    List<Widget> barCharts = [];

    if (deviceSensorData.isNotEmpty) {
      print('hi');
      deviceSensorData.values.first.keys.forEach((sensorType) {
        barCharts.add(
            _buildSensorBarChart(sensorType, _createBarChartData(sensorType)));
      });
    } else {
      barCharts.add(
        const Center(
          child: Text(
            'No sensor data available',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return barCharts;
  }

  Widget _buildSensorBarChart(
      String title, List<BarChartGroupData> barChartData) {
    // Sets min and max values for the Y-axis based on thresholds
    double minY = thresholds[title.toLowerCase()]?['low'] ?? 0.0;
    double maxY = thresholds[title.toLowerCase()]?['high'] ?? 100.0;
// Calculate the maximum length of device names
    double maxDeviceNameWidth = 0;
    for (var device in widget.devices) {
      final textSpan = TextSpan(
        text: device.name,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textScaleFactor: MediaQuery.of(context).textScaleFactor,
      )..layout();
      maxDeviceNameWidth = textPainter.size.width > maxDeviceNameWidth
          ? textPainter.size.width
          : maxDeviceNameWidth;
    }

    return Padding(
      // Adds padding around the entire chart
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              title[0].toUpperCase() +
                  title
                      .substring(1)
                      .toLowerCase(), // Capitalize the first letter
              textAlign: TextAlign
                  .start, // Aligns the text to start from the same point

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
              // Adds a bottom border to the chart container
              border: Border(
                bottom: BorderSide(
                  color: secondaryTextColor,
                  width: 0.1,
                ),
              ),
            ),
            height: 400, // Sets the height of the chart container
                        width: 400, // Sets the height of the chart container

            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                backgroundColor: Colors.transparent,
                barGroups: barChartData, // Provides the data for the bars
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, // Shows titles on the bottom axis
                      reservedSize: maxDeviceNameWidth +
                          30, // Ensures enough space for titles
                      getTitlesWidget: (value, _) {
                        // Function to create the widget for each title
                        final deviceName = widget.devices[value.toInt()]
                            .name; // Gets the device name
                        final textSpan = TextSpan(
                          text: deviceName, // Sets the text to the device name
                          style: const TextStyle(
                            color: secondaryTextColor, // Sets the text color
                            fontWeight:
                                FontWeight.normal, // Sets the text weight
                          ),
                        );
                        final textPainter = TextPainter(
                          text: textSpan, // Sets the text to be painted
                          textDirection:
                              TextDirection.ltr, // Left to right text direction
                          textScaleFactor: MediaQuery.of(context)
                              .textScaleFactor, // Adjusts for text scaling factor
                        )..layout(); // Lays out the text to calculate its size

                        final textHeight = textPainter
                            .size.height; // Gets the height of the text

                        return Align(
                          alignment: Alignment
                              .center, // Aligns the text at the bottom center
                          child: Container(
                            height: textHeight +
                                10, // Extra space to avoid trimming
                            child: Transform.rotate(
                              angle:
                                  -1.5708, // Rotates the text -90 degrees (in radians)
                              child: Text(
                                deviceName, // Displays the device name
                                textAlign: TextAlign
                                    .start, // Aligns the text to start from the same point
                                style: const TextStyle(
                                  color:
                                      secondaryTextColor, // Sets the text color
                                  fontWeight:
                                      FontWeight.normal, // Sets the text weight
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, // Shows titles on the left axis
                      getTitlesWidget: (value, _) {
                        return Text(
                          value
                              .toInt()
                              .toString(), // Displays the Y-axis values
                          style: const TextStyle(
                            color: secondaryTextColor,
                            fontWeight: FontWeight.normal,
                          ),
                        );
                      },
                      reservedSize: 40, // Reserves space for the left titles
                    ),
                  ),
                ),
                gridData: const FlGridData(show: true), // Shows the grid lines
                borderData:
                    FlBorderData(show: false), // Shows the border of the chart
                barTouchData: BarTouchData(
                  handleBuiltInTouches: true, // Handles touch interactions
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
                            text: '${rod.toY}', // Displays the value of the bar
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
                    fitInsideVertically: true,
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
}
