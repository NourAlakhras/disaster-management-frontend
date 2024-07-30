import 'package:flutter/material.dart';
import 'package:flutter_3/models/user_credentials.dart';
import 'package:flutter_3/screens/settings_screen.dart';
import 'package:flutter_3/services/mqtt_client_wrapper.dart';
import 'package:flutter_3/services/api_services/user_api_service.dart';
import 'package:flutter_3/utils/app_colors.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/services/api_services/admin_api_service.dart';
import 'package:flutter_3/utils/enums.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final mqttClient = MQTTClientWrapper();

  bool _isLoading = false;
  int allUsersCount = 0;
  int allMissionsCount = 0;
  int allDevicesCount = 0;
  int userCurrentMissionsCount = 0;
  Map<String, int> combinedUserCounts = {};
  Map<MissionStatus, int> missionCountByStatus = {};
  Map<String, int> combinedDeviceCounts = {};
  List<DeviceStatus>? _filteredStatuses = DeviceStatus.values
      .where((status) => status != DeviceStatus.INACTIVE)
      .toList();
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
        allUsersCount = await AdminApiService.getUserCount(context: context);
        allDevicesCount =
            await AdminApiService.getDeviceCount(context: context);
        allMissionsCount =
            await AdminApiService.getMissionCount(context: context);

        for (var status in UserStatus.values) {
          final count = await AdminApiService.getUserCount(
              context: context, status: [userStatusValues[status]!]);
          combinedUserCounts[getUserStatusTitle(status)] = count;
        }

        for (var type in UserType.values) {
          final count = await AdminApiService.getUserCount(
              context: context, type: [userTypeValues[type]!]);
          combinedUserCounts[getuserTypeTitle(type)] = count;
        }

        for (var status in MissionStatus.values) {
          missionCountByStatus[status] = await AdminApiService.getMissionCount(
              context: context, status: [missionStatusValues[status]!]);
        }

        for (var status in DeviceStatus.values) {

            final count = await AdminApiService.getDeviceCount(
                context: context, status: [deviceStatusValues[status]!]);
            combinedDeviceCounts[getDeviceStatusTitle(status)] = count;
          
        }

        for (var type in DeviceType.values) {
          final count = await AdminApiService.getDeviceCount(
            context: context,
            status: _filteredStatuses
                ?.map((status) => deviceStatusValues[status]!)
                .toList(),
            type: [deviceTypeValues[type]!],
          );
          combinedDeviceCounts[getDeviceTypeTitle(type)] = count;
        }
      } else {
        // Fetch regular user statistics
        userCurrentMissionsCount = await UserApiService.getCurrentMissionsCount(
          context: context,
        );

        for (var status in MissionStatus.values) {
          if (status != MissionStatus.CANCELLED &&
              status != MissionStatus.FINISHED) {
            missionCountByStatus[status] =
                await UserApiService.getCurrentMissionsCount(
                    context: context, statuses: [status]);
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
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
                      _buildSection('Devices Statistics', combinedDeviceCounts,
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
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
              gradient: const LinearGradient(
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
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              trailing: Text(
                '$totalCount',
                style: const TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
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

  String getuserTypeTitle(UserType userType) {
    return userType == UserType.REGULAR
        ? 'Active Regular Users'
        : 'Active Admin Users';
  }

Widget _buildStatisticsCard({required dynamic title, required int count}) {
    String titleString =
        title is Enum ? getTitleFromEnum(title) : title.toString();

    return Container(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [cardColor, barColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate the responsive font size based on the constraints
            double titleFontSize =
                constraints.maxWidth * 0.080; // Adjust the ratio as needed
            double countFontSize =
                constraints.maxWidth * 0.12; // Adjust the ratio as needed

            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 30, 12, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleString,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Count: $count',
                    style: TextStyle(
                      fontSize: countFontSize,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            );
          },
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

  String getDeviceTypeTitle(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.UGV:
        return 'Active UGVs';
      case DeviceType.UAV:
        return 'Active UAVs';
      case DeviceType.DOG:
        return 'Active Dogs';
      case DeviceType.CHARGING_STATION:
        return 'Active Charging Stations';
      case DeviceType.BROKER:
        return 'Active Brokers';
      default:
        return '';
    }
  }
}
