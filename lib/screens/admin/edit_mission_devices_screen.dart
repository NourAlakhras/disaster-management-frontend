import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/selection_widget.dart';

class EditDevicesScreen extends StatefulWidget {
  final List<Device>? preselectedDevices;
  final String? missionId;
  final String? brokerId; // Add brokerId parameter

  EditDevicesScreen({
    this.preselectedDevices,
    this.missionId,
    this.brokerId,
  }); // Modify constructor
  @override
  _EditDevicesScreenState createState() => _EditDevicesScreenState();
}

class _EditDevicesScreenState extends State<EditDevicesScreen> {
  late List<Device> _deviceOptions;
  late List<Device> _selectedDevices = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDevices = widget.preselectedDevices ?? [];
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final typesToInclude =
          DeviceType.values.where((type) => type != DeviceType.BROKER).toList();
      final deviceResponse = await DeviceApiService.getAllDevices(
        pageNumber: 1,
        pageSize: 100,
        statuses: [DeviceStatus.AVAILABLE],
        types: typesToInclude,
        missionId: widget.missionId,
        brokerId: widget.brokerId, // Fetch devices by broker ID
      );
      setState(() {
        _deviceOptions = deviceResponse.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to fetch devices: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Devices'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop<List<Device>>(context, _selectedDevices);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SelectionWidget<Device>(
              items: _deviceOptions,
              preselectedItems: _selectedDevices,
              onSelectionChanged: (selectedDevices) {
                setState(() {
                  _selectedDevices = selectedDevices;
                });
              },
            ),
    );
  }
}
