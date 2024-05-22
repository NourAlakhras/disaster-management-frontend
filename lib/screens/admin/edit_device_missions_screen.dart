import 'package:flutter/material.dart';
import 'package:flutter_3/models/mission.dart';
import 'package:flutter_3/services/mission_api_service.dart';
import 'package:flutter_3/utils/enums.dart';
import 'package:flutter_3/widgets/selection_widget.dart';

class EditMissionsScreen extends StatefulWidget {
  final List<Mission>? preselectedMissions;

  EditMissionsScreen(
      {this.preselectedMissions}); // Modify constructor
  @override
  _EditMissionsScreenState createState() => _EditMissionsScreenState();
}

class _EditMissionsScreenState extends State<EditMissionsScreen> {
  late List<Mission> _missionOptions;
  late List<Mission> _selectedMissions = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedMissions = widget.preselectedMissions ?? [];

    _fetchMissions();
  }

  Future<void> _fetchMissions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      
      final List<Mission> missions = await MissionApiService.getAllMissions(
        pageNumber: 1,
        pageSize: 100,
        statuses: [
          MissionStatus.CREATED,
          MissionStatus.ONGOING,
          MissionStatus.PAUSED,
        ],
      );
      setState(() {
        _missionOptions = missions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to fetch missions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Missions'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop<List<Mission>>(context, _selectedMissions);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SelectionWidget<Mission>(
              items: _missionOptions,
              preselectedItems: _selectedMissions,
              onSelectionChanged: (selectedMissions) {
                setState(() {
                  _selectedMissions = selectedMissions;
                });
              },
            ),
    );
  }
}
