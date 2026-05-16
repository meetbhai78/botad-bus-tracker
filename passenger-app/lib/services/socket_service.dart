import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants.dart';

class PassengerSocketService {
  IO.Socket? socket;
  void Function(List<dynamic>)? onBuses;

  void connect() {
    socket = IO.io(socketUrl, IO.OptionBuilder().setTransports(['websocket']).build());
    socket!.connect();
    socket!.on('buses:locations', (data) {
      if (data is List) onBuses?.call(data);
    });
  }

  void watchBus(String busId) {
    socket?.emit('passenger:watch', {'busId': busId});
  }

  void dispose() => socket?.disconnect();
}
