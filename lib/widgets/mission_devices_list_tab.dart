import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/models/user_credentials.dart';
import 'package:flutter_3/screens/device_profile.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/utils/app_colors.dart';

class MissionDevicesListTab extends StatefulWidget {
  final List<Device> devices;
  const MissionDevicesListTab({
    super.key,
    required this.devices,
  });

  @override
  State<MissionDevicesListTab> createState() => _MissionDevicesListTabState();
}

class _MissionDevicesListTabState extends State<MissionDevicesListTab> {
  int _pageNumber = 1;
  final int _pageSize = 5;
  final mqttClient = MQTTClientWrapper();

  @override
  Widget build(BuildContext context) {
    int startIndex = (_pageNumber - 1) * _pageSize;
    int endIndex = startIndex + _pageSize;
    List<Device> currentDevices = widget.devices.sublist(
      startIndex,
      endIndex > widget.devices.length ? widget.devices.length : endIndex,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15.0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.devices.isEmpty)
            const Center(
              child: Text(
                'No devices available',
                style: TextStyle(color: primaryTextColor),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Labels Row
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: accentColor),
                        ),
                      ),
                      height: 60,
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text('Device Name',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: primaryTextColor)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('Type',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color:
                                        primaryTextColor)), // Light text color
                          ),
                          Expanded(
                            flex: 2,
                            child: SizedBox(), // Placeholder for actions column
                          ),
                        ],
                      ),
                    ),
                    // Device Rows
                    ...currentDevices.map((device) {
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeviceProfileScreen(
                              device: device,
                            ),
                          ),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: barColor,
                              ),
                            ),
                          ),
                          height: 70,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Text(device.name,
                                    style: const TextStyle(
                                        fontSize: 17,
                                        color:
                                            secondaryTextColor)), // Light text color
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                    device.type
                                        .toString()
                                        .split('.')
                                        .last
                                        .toLowerCase(),
                                    style: const TextStyle(
                                        fontSize: 17,
                                        color:
                                            secondaryTextColor)), // Light text color
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: _buildDeviceActions(device),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10.0, 20, 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _pageNumber > 1
                    ? ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (_pageNumber > 1) _pageNumber--;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: accentColor,
                          backgroundColor: secondaryTextColor,
                          elevation: 0, // No shadow
                          shape: const CircleBorder(), // Circular button shape
                        ),
                        child: const Icon(Icons.arrow_back),
                      )
                    : const SizedBox(width: 48, height: 48),
                _pageNumber < (widget.devices.length / _pageSize).ceil()
                    ? ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (_pageNumber <
                                (widget.devices.length / _pageSize).ceil()) {
                              _pageNumber++;
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: accentColor,
                          backgroundColor: secondaryTextColor,
                          elevation: 0, // No shadow
                          shape: const CircleBorder(), // Circular button shape
                        ),
                        child: const Icon(Icons.arrow_forward),
                      )
                    : const SizedBox(width: 48, height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDeviceActions(Device device) {
    if (UserCredentials().getUserType() == UserType.ADMIN) {
      return (device.status != DeviceStatus.INACTIVE)
          ? [
              PopupMenuButton<int>(
                icon: const Icon(Icons.more_vert, color: secondaryTextColor),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 1,
                    child: Text('Delete'),
                  ),
                ],
                onSelected: (value) {
                  if (value == 1) {
                    _deleteDevice(device.device_id);
                  }
                },
              )
            ]
          : [];
    } else {
      return [];
    }
  }

  void _deleteDevice(String id) {
    DeviceApiService.deleteDevice(deviceId: id, context: context)
        .then((deletedDevice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Device deleted successfully'),
          backgroundColor: successColor,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete device: $error'),
          backgroundColor: errorColor,
        ),
      );
    });
  }
}
