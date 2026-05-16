import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/gps_service.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';

/// Active trip — GPS + Socket har ~3 sec
class TripScreen extends StatefulWidget {
  const TripScreen({super.key, required this.busId, this.tripId});

  final String busId;
  final String? tripId;

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  final _gps = GpsService();
  final _socket = SocketService();
  final MapController _mapController = MapController();
  LatLng _position = const LatLng(22.1647, 71.6661);
  double _speed = 0;
  StreamSubscription? _gpsSub;
  Timer? _emitTimer;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _startTracking() async {
    if (!await _gps.ensurePermission()) return;
    final token = await AuthService().getToken();
    if (token != null) _socket.connect(token);

    _gpsSub = _gps.getLocationStream().listen((pos) {
      if (!mounted) return;
      setState(() {
        _position = LatLng(pos.latitude, pos.longitude);
        _speed = pos.speed * 3.6; // m/s → km/h
      });
      if (_mapReady) {
        _mapController.move(_position, 16.0);
      }
    });

    _emitTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _socket.sendLocation(
        busId: widget.busId,
        lat: _position.latitude,
        lng: _position.longitude,
        speed: _speed,
        tripId: widget.tripId,
      );
    });
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _emitTimer?.cancel();
    _socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Trip')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _position,
                initialZoom: 15.0,
                onMapReady: () {
                  setState(() {
                    _mapReady = true;
                  });
                },
              ),
              children: [
                TileLayer(
                  // MapTiler Vector/Raster URL using the provided key
                  urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=d39cWWFDlw1ibSbMysvD',
                  userAgentPackageName: 'com.botad.driver',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _position,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Text('${_speed.toStringAsFixed(0)} km/h',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                const Text('Next stop: Botad Hospital · 1.2 km'),
                const SizedBox(height: 8),
                const Text('Passengers: 0'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('End Trip'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
