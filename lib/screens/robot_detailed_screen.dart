import 'package:flutter/material.dart';
import 'package:flutter_3/widgets/monitoring_view.dart'; 
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/tabbed_view.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';

class RobotDetailedScreen extends StatefulWidget {
  final String robotId;
  final String mqttTopic;
  final MQTTClientWrapper mqttClient;

  const RobotDetailedScreen({
    Key? key,
    required this.robotId,
    required this.mqttTopic,
    required this.mqttClient
  }) : super(key: key);

  @override
  _RobotDetailedScreenState createState() => _RobotDetailedScreenState();
}

class _RobotDetailedScreenState extends State<RobotDetailedScreen> {
  late MQTTClientWrapper mqttClient;
  Map<String, dynamic> receivedData = {};

  @override
  void initState() {
    super.initState();
    mqttClient = widget.mqttClient;
    mqttClient.onDataReceived = onDataReceived;
    mqttClient.subscribeToTopic(widget.mqttTopic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121417),
      appBar: CustomUpperBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color.fromARGB(255, 255, 255, 255),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: 'Robot Details - ${widget.robotId}',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            color: const Color.fromARGB(255, 255, 255, 255),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height / 3,
            width: double.infinity,
            child: Container(
              width: 175,
              height: 175,
              color: Colors.grey[300],
              child: Center(
                child: Icon(
                  Icons.video_library,
                  size: 100,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabbedView(
              length: 2,
              tabs: const <Widget>[
                Tab(
                  text: 'Monitoring',
                ),
                Tab(
                  text: 'Controlling',
                ),
              ],
              tabContents: [
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  child: MonitoringView(
                    robotId: widget.robotId,
                    mqttTopic: widget.mqttTopic,
                    mqttClient: mqttClient,
                    receivedData: receivedData,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  child: const Text('Controlling'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onDataReceived(Map<String, dynamic> data) {
    setState(() {
      receivedData = data;
    });
  }

  @override
  void dispose() {
    mqttClient.unsubscribeFromTopic(widget.mqttTopic);
    super.dispose();
  }
}
