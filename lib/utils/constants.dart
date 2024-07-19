// constants.dart
import 'package:flutter/material.dart';

class Constants {
  // Base IP address
  static const String baseIpAddress = '51.79.158.202';

  // Web server base URL
  static const String webServerBaseUrl = 'http://$baseIpAddress:8080';

  // RTMP stream URL
  static const String rtmpStreamUrl = 'rtmp://$baseIpAddress/live';

  // MQTT broker URL
  static const String mqttBrokerUrl = '$baseIpAddress';

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
