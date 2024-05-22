import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/selection_widget.dart';

class EditBrokersScreen extends StatefulWidget {
  final List<Device>? preselectedBrokers;
  final String? missionId;
    final bool? singleSelection; 


  EditBrokersScreen(
      {this.preselectedBrokers, this.missionId,
    this.singleSelection,
  }); 
  @override
  _EditBrokersScreenState createState() => _EditBrokersScreenState();
}

class _EditBrokersScreenState extends State<EditBrokersScreen> {
  late List<Device> _brokerOptions;
  late List<Device> _selectedBrokers = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedBrokers = widget.preselectedBrokers ?? [];

    _fetchBrokers();
  }

  Future<void> _fetchBrokers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<Device> brokers = await DeviceApiService.getAllDevices(
        pageNumber: 1,
        pageSize: 100,
        statuses: [DeviceStatus.AVAILABLE],
        types: [DeviceType.BROKER],
        missionId: widget.missionId,
      );
      setState(() {
        _brokerOptions = brokers;
        print('_fetchBrokers $brokers');
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to fetch brokers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select brokers'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop<List<Device>>(context, _selectedBrokers);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SelectionWidget<Device>(
              items: _brokerOptions,
              preselectedItems: _selectedBrokers,
              onSelectionChanged: (selectedBrokers) {
                setState(() {
                  _selectedBrokers = selectedBrokers;
                });
              },
              singleSelection: widget.singleSelection,
            ),
    );
  }
}
