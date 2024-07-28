import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/services/api_services/device_api_service.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/selection_widget.dart';
import 'package:flutter_3/utils/app_colors.dart';

class EditMissionDevicesScreen extends StatefulWidget {
  final List<Device>? preselectedDevices;
  final String? missionId;
  final String? brokerId; // Add brokerId parameter

  EditMissionDevicesScreen({
    this.preselectedDevices,
    this.missionId,
    this.brokerId,
  }); // Modify constructor
  @override
  _EditMissionDevicesScreenState createState() =>
      _EditMissionDevicesScreenState();
}

class _EditMissionDevicesScreenState extends State<EditMissionDevicesScreen> {
  late List<Device> _deviceOptions;
  late List<Device> _selectedDevices = [];

  bool _isLoading = false;
  int _pageNumber = 1;
  bool _hasNext = false;
  bool _hasPrev = false;

  @override
  void initState() {
    super.initState();
    _selectedDevices = widget.preselectedDevices ?? [];
    _fetchDevices();
  }

  Future<void> _fetchDevices({int pageNumber = 1}) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final typesToInclude =
          DeviceType.values.where((type) => type != DeviceType.BROKER).toList();
      final deviceResponse = await DeviceApiService.getAllDevices(
        pageNumber: pageNumber,
        pageSize: 5,
        statuses: [DeviceStatus.AVAILABLE, DeviceStatus.ASSIGNED],
        types: typesToInclude,
        brokerId: widget.brokerId, context: context, // Fetch devices by broker ID
      );
      if (!mounted) return;

      setState(() {
        _deviceOptions = deviceResponse.items;
        _pageNumber = deviceResponse.page;
        _hasNext = deviceResponse.hasNext;
        _hasPrev = deviceResponse.hasPrev;
        _isLoading = false;
        print('_deviceOptions $_deviceOptions');
      });

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to fetch devices: $e');
    }
  }

  void _nextPage() {
    if (_hasNext) {
      _fetchDevices(pageNumber: _pageNumber + 1);
    }
  }

  void _previousPage() {
    if (_hasPrev) {
      _fetchDevices(pageNumber: _pageNumber - 1);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomUpperBar(
        title: 'Select Devices',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: primaryTextColor,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.check),
            color: primaryTextColor,
            onPressed: () {
              Navigator.pop<List<Device>>(context, _selectedDevices);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(15, 8, 15.0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: secondaryTextColor),
                ),
              ),
              height: 60,
              child: const Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text("Device's name",
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
                            color: primaryTextColor)),
                  ),
                  Expanded(
                    flex: 2,
                    child: SizedBox(),
                  ),
                ],
              ),
            ),
            // Device List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SelectionWidget<Device>(
                      items: _deviceOptions,
                      preselectedItems: _selectedDevices,
                      singleSelection: false,
                      onSelectionChanged: (selectedDevices) {
                        setState(() {
                          _selectedDevices = selectedDevices;
                          print('ho');
                        });
                      },
                      itemBuilder: (device, isSelected) =>
                          _buildDeviceTile(device, isSelected),
                    ),
            ),
            // Pagination Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10.0, 20, 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _hasPrev ? _previousPage : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: accentColor,
                      backgroundColor: secondaryTextColor,
                      elevation: 0,
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(Icons.arrow_back),
                  ),
                  ElevatedButton(
                    onPressed: _hasNext ? _nextPage : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: accentColor,
                      backgroundColor: secondaryTextColor,
                      elevation: 0,
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceTile(Device device, bool isSelected) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: barColor),
        ),
      ),
      height: 70,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              device.name,
              style: const TextStyle(fontSize: 17, color: secondaryTextColor),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              device.type.toString().split('.').last.toLowerCase(),
              style: const TextStyle(fontSize: 17, color: secondaryTextColor),
            ),
          ),
          Checkbox(
            value: isSelected,
            onChanged: (bool? value) {},
          ),
        ],
      ),
    );
  }
}
