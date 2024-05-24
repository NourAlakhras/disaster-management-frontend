import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/screens/admin/device_profile.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/utils/enums.dart';

class MissionDevicesListTab extends StatefulWidget {
  final MQTTClientWrapper mqttClient;
  final List<Device> devices;
  const MissionDevicesListTab({
    super.key,
    required this.mqttClient,
    required this.devices,
  });

  @override
  State<MissionDevicesListTab> createState() => _MissionDevicesListTabState();
}

class _MissionDevicesListTabState extends State<MissionDevicesListTab> {
  int _pageNumber = 1;
  final int _pageSize = 5;

  @override
  Widget build(BuildContext context) {
    int startIndex = (_pageNumber - 1) * _pageSize;
    int endIndex = startIndex + _pageSize;
    List<Device> currentDevices = widget.devices.sublist(
      startIndex,
      endIndex > widget.devices.length ? widget.devices.length : endIndex,
    );

    return Container(
      color: const Color(0xff121417),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15.0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.devices.isEmpty)
              const Center(
                child: Text(
                  'No devices available',
                  style: TextStyle(color: Colors.white),
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
                            bottom: BorderSide(color: Colors.grey),
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
                                      color: Colors.white)),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('Type',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white)), // Light text color
                            ),
                            Expanded(
                              flex: 2,
                              child:
                                  SizedBox(), // Placeholder for actions column
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
                                mqttClient: widget.mqttClient,
                              ),
                            ),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Color(0xff293038),
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
                                          color: Colors
                                              .white70)), // Light text color
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
                                          color: Colors
                                              .white70)), // Light text color
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
                      ?                   ElevatedButton(

                          onPressed: () {
                            setState(() {
                              if (_pageNumber > 1) _pageNumber--;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.white70,
                            elevation: 0, // No shadow
                            shape:
                                const CircleBorder(), // Circular button shape
                          ),
                          child: const Icon(Icons.arrow_back),
                        )
                      : const SizedBox(
                          width: 48,
                          height:
                              48), 
                  _pageNumber < (widget.devices.length / _pageSize).ceil()
                      ?  ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if (_pageNumber <
                                  (widget.devices.length / _pageSize).ceil()) {
                                _pageNumber++;
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.white70,
                            elevation: 0, // No shadow
                            shape:
                                const CircleBorder(), // Circular button shape
                          ),
                          child: const Icon(Icons.arrow_forward),
                        )
                      : const SizedBox(
                          width: 48,
                          height:
                              48), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDeviceActions(Device device) {
    return (device.status != DeviceStatus.INACTIVE)
        ? [
            PopupMenuButton<int>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
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
  }

  void _deleteDevice(String id) {
    DeviceApiService.deleteDevice(id).then((deletedDevice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete device: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
}
