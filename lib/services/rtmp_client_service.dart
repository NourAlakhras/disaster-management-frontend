import 'package:flutter_3/models/user_credentials.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:flutter_3/utils/constants.dart';

class RTMPClientService {
  final Map<String, VlcPlayerController> _controllers = {};

  VlcPlayerController? getController(String deviceId) {
    print('Getting controller for device $deviceId');
    return _controllers[deviceId];
  }

  Future<void> initializePlayer({
    required String deviceId,
    required String deviceName,
  }) async {
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

    controller.addListener(() {
      print('Controller state for device $deviceId: ${controller.value}');
    });

    controller.addOnInitListener(() {
      print('Controller initialized for device $deviceId');
    });

    controller.addOnRendererEventListener(
      (VlcRendererEventType type, String id, String name) {
        print(
            'Renderer event for device $deviceId: type=$type, id=$id, name=$name');
        if (type == VlcRendererEventType.detached) {
          print('Renderer detached for device $deviceId');
        }
      },
    );

    try {
      _controllers[deviceId] = controller;
      print('Player successfully initialized for device $deviceId');
    } catch (e) {
      print('Error initializing player for device $deviceId: $e');
    }
  }

  void disposeController(String deviceId) {
    print('Disposing controller for device $deviceId');
    try {
      _controllers[deviceId]?.dispose();
      _controllers.remove(deviceId);
      print('Controller successfully disposed for device $deviceId');
    } catch (e) {
      print('Error disposing controller for device $deviceId: $e');
    }
  }

  void disposeAll() {
    print('Disposing all controllers');
    try {
      for (var controller in _controllers.values) {
        controller.dispose();
      }
      _controllers.clear();
      print('All controllers successfully disposed');
    } catch (e) {
      print('Error disposing all controllers: $e');
    }
  }
}
