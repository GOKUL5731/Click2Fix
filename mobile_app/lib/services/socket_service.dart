import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/app_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  
  void connect(String token) {
    if (_socket != null && _socket!.connected) return;
    
    _socket = IO.io(AppConfig.socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .setAuth({'token': token})
      .build());
      
    _socket!.connect();
    
    _socket!.onConnect((_) {
      print('Socket connected');
    });
    
    _socket!.onDisconnect((_) {
      print('Socket disconnected');
    });
  }
  
  void joinBooking(String bookingId) {
    _socket?.emit('booking.join', {'bookingId': bookingId});
  }

  void sendMessage(String bookingId, String message) {
    _socket?.emit('chat.message', {'bookingId': bookingId, 'message': message});
  }

  void sendLocation(String bookingId, double lat, double lng) {
    _socket?.emit('location.updated', {'bookingId': bookingId, 'latitude': lat, 'longitude': lng});
  }

  void onMessage(Function(dynamic) callback) {
    _socket?.on('chat.message', callback);
  }

  void onLocationUpdate(Function(dynamic) callback) {
    _socket?.on('location.updated', callback);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
