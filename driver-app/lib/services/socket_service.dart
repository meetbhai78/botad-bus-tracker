import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants.dart';

/// Socket.io — driver location har 3 sec (server se match)
class SocketService {
  IO.Socket? socket;

  void connect(String token) {
    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setAuth({'token': token})
          .setTransports(['websocket'])
          .build(),
    );
    socket!.connect();
  }

  void sendLocation({
    required String busId,
    required double lat,
    required double lng,
    required double speed,
    String? tripId,
    double? heading,
  }) {
    socket?.emit('driver:location', {
      'busId': busId,
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'heading': heading,
      'tripId': tripId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void disconnect() {
    socket?.disconnect();
    socket = null;
  }
}
