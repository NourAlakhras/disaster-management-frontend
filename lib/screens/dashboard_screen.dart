import 'package:flutter/material.dart';
import 'package:flutter_3/models/user_credentials.dart';
import 'package:flutter_3/screens/settings_screen.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/services/user_api_service.dart';
import 'package:flutter_3/utils/app_colors.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/services/admin_api_service.dart';
import 'package:flutter_3/utils/enums.dart';

class DashboardScreen extends StatefulWidget {
  final MQTTClientWrapper mqttClient;

  const DashboardScreen({super.key, required this.mqttClient});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  int allUsersCount = 0;
  int allMissionsCount = 0;
  int allDevicesCount = 0;
  int userCurrentMissionsCount = 0;
  Map<String, int> combinedUserCounts = {};
  Map<MissionStatus, int> missionCountByStatus = {};
  Map<DeviceStatus, int> deviceCountByStatus = {};

  @override
  void initState() {
    super.initState();
    _fetchCounts();
  }

  Future<void> _fetchCounts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final userType = UserCredentials().getUserType();

    try {
      if (userType == UserType.ADMIN) {
        // Fetch admin statistics
        allUsersCount = await AdminApiService.getUserCount();
        allDevicesCount = await AdminApiService.getDeviceCount();
        allMissionsCount = await AdminApiService.getMissionCount();

        for (var status in UserStatus.values) {
          if (status != UserStatus.REJECTED) {
            final count = await AdminApiService.getUserCount(
                status: [userStatusValues[status]!]);
            combinedUserCounts[getUserStatusTitle(status)] = count;
          }
        }

        for (var type in UserType.values) {
          final count =
              await AdminApiService.getUserCount(type: [userTypeValues[type]!]);
          combinedUserCounts[getuserTypeTitle(type)] = count;
        }

        for (var status in MissionStatus.values) {
          if (status != MissionStatus.CANCELLED) {
            missionCountByStatus[status] =
                await AdminApiService.getMissionCount(
                    status: [missionStatusValues[status]!]);
          }
        }

        for (var status in DeviceStatus.values) {
          if (status != DeviceStatus.INACTIVE) {
            deviceCountByStatus[status] = await AdminApiService.getDeviceCount(
                status: [deviceStatusValues[status]!]);
          }
        }
      } else {
        // Fetch regular user statistics
        userCurrentMissionsCount =
            await UserApiService.getCurrentMissionsCount();

        for (var status in MissionStatus.values) {
          if (status != MissionStatus.CANCELLED &&
              status != MissionStatus.FINISHED) {
            missionCountByStatus[status] =
                await UserApiService.getCurrentMissionsCount(
                    statuses: [status]);
          }
        }
      }
    } catch (e) {
      print('Error fetching counts: $e');
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userType = UserCredentials().getUserType();

    if (userType == UserType.ADMIN) {
      return Scaffold(
        appBar: CustomUpperBar(
          title: "Dashboard",
          leading: IconButton(
            icon: const Icon(Icons.settings),
            color: primaryTextColor,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      SettingsScreen(mqttClient: widget.mqttClient)),
            ).then((_) {
              setState(() {
                // Call setState to refresh the page.
              });
            }),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              color: primaryTextColor,
              onPressed: () {},
            )
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 0, 15.0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection('Users Statistics', combinedUserCounts,
                          allUsersCount),
                      _buildSection('Missions Statistics', missionCountByStatus,
                          allMissionsCount),
                      _buildSection('Devices Statistics', deviceCountByStatus,
                          allDevicesCount),
                    ],
                  ),
                ),
              ),
      );
    } else {
      return Scaffold(
        appBar: CustomUpperBar(
          title: "Dashboard",
          leading: IconButton(
            icon: const Icon(Icons.settings),
            color: primaryTextColor,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      SettingsScreen(mqttClient: widget.mqttClient)),
            ).then((_) {
              setState(() {
                // Call setState to refresh the page.
              });
            }),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              color: primaryTextColor,
              onPressed: () {},
            )
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 0, 15.0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection('My Missions Statistics',
                          missionCountByStatus, userCurrentMissionsCount),
                    ],
                  ),
                ),
              ),
      );
    }
  }

  Widget _buildSection(String title, Map<dynamic, int> data, int totalCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: primaryTextColor,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cardColor, barColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListTile(
              title: const Text(
                'Total:',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 18,
                ),
              ),
              trailing: Text(
                '$totalCount',
                style: const TextStyle(
                  color: primaryTextColor,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildGrid(data),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildGrid(Map<dynamic, int> data) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 20.0,
      mainAxisSpacing: 20.0,
      children: data.entries.map((entry) {
        return AspectRatio(
          aspectRatio: 2.5,
          child: _buildStatisticsCard(
            title: entry.key,
            count: entry.value,
          ),
        );
      }).toList(),
    );
  }

  String getUserStatusTitle(UserStatus status) {
    switch (status) {
      case UserStatus.AVAILABLE:
        return 'Available Users';
      case UserStatus.PENDING:
        return 'Pending Users';
      case UserStatus.ASSIGNED:
        return 'Assigned Users';
      case UserStatus.INACTIVE:
        return 'Inactive Users';
      case UserStatus.REJECTED:
        return 'Rejected Users';
      default:
        return '';
    }
  }

  String getuserTypeTitle(UserType userType) {
    return userType == UserType.REGULAR ? 'Regular Users' : 'Admin Users';
  }

  Widget _buildStatisticsCard({required dynamic title, required int count}) {
    String titleString =
        title is Enum ? getTitleFromEnum(title) : title.toString();
    return Container(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          // ignore: prefer_const_constructors
          gradient: LinearGradient(
            colors: [cardColor, barColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8.0),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.white.withOpacity(0.4),
          //     spreadRadius: 2,
          //     blurRadius: 2,
          //     offset: const Offset(0, 1),
          //   ),
          // ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 30, 12, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleString,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Count: $count',
                style: const TextStyle(
                  fontSize: 18,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getTitleFromEnum(dynamic enumValue) {
    if (enumValue is UserStatus) {
      return getUserStatusTitle(enumValue);
    } else if (enumValue is UserType) {
      return getuserTypeTitle(enumValue);
    } else if (enumValue is MissionStatus) {
      return getMissionStatusTitle(enumValue);
    } else if (enumValue is DeviceStatus) {
      return getDeviceStatusTitle(enumValue);
    }
    return '';
  }

  String getMissionStatusTitle(MissionStatus missionStatus) {
    switch (missionStatus) {
      case MissionStatus.CREATED:
        return 'Created Missions';
      case MissionStatus.ONGOING:
        return 'Ongoing Missions';
      case MissionStatus.PAUSED:
        return 'Paused Missions';
      case MissionStatus.CANCELLED:
        return 'CANCELLED Missions';
      case MissionStatus.FINISHED:
        return 'Finished Missions';
      default:
        return '';
    }
  }

  String getDeviceStatusTitle(DeviceStatus deviceStatus) {
    switch (deviceStatus) {
      case DeviceStatus.AVAILABLE:
        return 'Available Devices';
      case DeviceStatus.ASSIGNED:
        return 'Assigned Devices';
      case DeviceStatus.INACTIVE:
        return 'Inactive Devices';
      default:
        return '';
    }
  }
}
