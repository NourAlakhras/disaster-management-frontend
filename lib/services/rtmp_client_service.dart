import 'package:flutter_3/services/mqtt_client_wrapper.dart';
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
    print('url $url');

    final controller = VlcPlayerController.network(
      url,
      autoPlay: true,
      onRendererHandler: (eventType, id, event) {
        switch (eventType) {
          case VlcRendererEventType.attached:
            print('Renderer attached: $event');
            break;
          case VlcRendererEventType.detached:
            print('Renderer detached: $event');
            break;
          case VlcRendererEventType.unknown:
            print('Unknown renderer event: $event');
            break;
        }
      },
    );

    await controller.initialize();
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
