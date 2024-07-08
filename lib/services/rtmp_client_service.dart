import 'package:flutter_3/models/user_credentials.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:flutter_3/utils/constants.dart';

class RTMPClientService {
  final Map<String, VlcPlayerController> _controllers = {};

  VlcPlayerController getController(String deviceId) => _controllers[deviceId]!;

  Future<void> initializePlayer(
      {required String deviceId, required String deviceName}) async {
    const String rtmpStreamUrl = Constants.rtmpStreamUrl;
    final String url =
        '$rtmpStreamUrl/$deviceName?username=${UserCredentials().username}&password=${UserCredentials().password}';
    print('Initializing player for device $deviceId with URL: $url');

    VlcPlayerOptions options = VlcPlayerOptions(
      advanced: VlcAdvancedOptions([
        VlcAdvancedOptions.networkCaching(
            0), // Set network caching to 0ms (minimal buffering)
        VlcAdvancedOptions.liveCaching(0), // Set live caching to 0ms
        VlcAdvancedOptions.fileCaching(0), // Set file caching to 0ms

      ]),
    );

    final controller = VlcPlayerController.network(
      url,
      allowBackgroundPlayback: true,
      autoPlay: true,
      autoInitialize: true,
      options: options,
    );
    _controllers[deviceId] = controller;
  }

  void disposeController(String deviceId) {
    _controllers[deviceId]?.dispose();
    _controllers.remove(deviceId);
  }

  void disposeAll() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }
}
