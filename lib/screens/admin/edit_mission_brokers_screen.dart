import 'package:flutter/material.dart';
import 'package:flutter_3/models/device.dart';
import 'package:flutter_3/services/device_api_service.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/selection_widget.dart';
import 'package:flutter_3/utils/app_colors.dart';

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
  int _pageNumber = 1;
  bool _hasNext = false;
  bool _hasPrev = false;

  @override
  void initState() {
    super.initState();
    _selectedBroker = widget.preselectedBroker;
    _fetchBrokers();
  }

  Future<void> _fetchBrokers({int pageNumber = 1}) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final brokerResponse = await DeviceApiService.getAllDevices(
        pageNumber: pageNumber,
        pageSize: 5,
        statuses: [DeviceStatus.AVAILABLE],
        types: [DeviceType.BROKER],
        missionId: widget.missionId,
      );
      if (!mounted) return;

      setState(() {
        _brokerOptions = brokerResponse.items;
        _pageNumber = brokerResponse.page;
        _hasNext = brokerResponse.hasNext;
        _hasPrev = brokerResponse.hasPrev;
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

  void _nextPage() {
    if (_hasNext) {
      _fetchBrokers(pageNumber: _pageNumber + 1);
    }
  }

  void _previousPage() {
    if (_hasPrev) {
      _fetchBrokers(pageNumber: _pageNumber - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomUpperBar(
        title: 'Select Broker',
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
              Navigator.pop<Device>(context, _selectedBroker);
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
                    child: Text("Broker's name",
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
            ), // Broker List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SelectionWidget<Device>(
                      items: _brokerOptions,
                      preselectedItems:
                          _selectedBroker != null ? [_selectedBroker!] : [],
                      onSelectionChanged: (selectedBrokers) {
                        setState(() {
                          _selectedBroker = selectedBrokers.isNotEmpty
                              ? selectedBrokers.first
                              : null;
                        });
                      },
                      itemBuilder: (broker, isSelected) =>
                          _buildBrokerTile(broker, isSelected),
                      singleSelection: widget.singleSelection,
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

  Widget _buildBrokerTile(Device broker, bool isSelected) {
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
              broker.name,
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
