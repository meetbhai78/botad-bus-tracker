import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants.dart';

class SocketService {
  IO.Socket? socket;
  void Function(List<dynamic>)? onBuses;
  void Function(Map<String, dynamic>)? onStopEta;

  void connect() {
    socket = IO.io(socketUrl, IO.OptionBuilder().setTransports(['websocket']).build());
    socket!.connect();
    socket!.on('buses:locations', (data) {
      if (data is List) onBuses?.call(data);
    });
    socket!.on('stop:eta', (data) {
      if (data is Map) {
        onStopEta?.call(Map<String, dynamic>.from(data));
      }
    });
  }

  void watchBus(String busId) {
    socket?.emit('passenger:watch', {'busId': busId});
  }

  void watchStop(String stopId) {
    socket?.emit('passenger:watchStop', {'stopId': stopId});
  }

  void dispose() => socket?.disconnect();
}

typedef PassengerSocketService = SocketService;
