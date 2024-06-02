import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/selection_widget.dart';

class EditBrokersScreen extends StatefulWidget {
  final Device? preselectedBroker;
  final String? missionId;
  final bool singleSelection;

  EditBrokersScreen({
    this.preselectedBroker,
    this.missionId,
    this.singleSelection = true,
  });

  @override
  _EditBrokersScreenState createState() => _EditBrokersScreenState();
}

class _EditBrokersScreenState extends State<EditBrokersScreen> {
  List<Device> _brokerOptions = [];
  Device? _selectedBroker;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedBroker = widget.preselectedBroker;
    _fetchBrokers();
  }

  Future<void> _fetchBrokers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final brokerResponse = await DeviceApiService.getAllDevices(
        pageNumber: 1,
        pageSize: 100,
        statuses: [DeviceStatus.AVAILABLE],
        types: [DeviceType.BROKER],
        missionId: widget.missionId,
      );
          if (!mounted) return;

      setState(() {
        _brokerOptions = brokerResponse.items;
        _isLoading = false;
        print('_brokerOptions $_brokerOptions');

      });
    } catch (e) {
          if (!mounted) return;

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
        title: const Text('Select Broker'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop<Device>(context, _selectedBroker);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SelectionWidget<Device>(
              items: _brokerOptions,
              preselectedItems:
                  _selectedBroker != null ? [_selectedBroker!] : [],
              onSelectionChanged: (selectedBrokers) {
                setState(() {
                  _selectedBroker =
                      selectedBrokers.isNotEmpty ? selectedBrokers.first : null;
                });
              },
              singleSelection: widget.singleSelection,
            ),
    );
  }
}
