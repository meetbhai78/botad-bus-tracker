import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../services/gps_service.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import '../constants.dart';

/// Active trip — GPS + Socket har ~3 sec
class TripScreen extends StatefulWidget {
  const TripScreen({super.key, required this.busId, required this.routeName, this.tripId});

  final String busId;
  final String routeName;
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
  bool _isEnding = false;

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

  Future<void> _endTrip() async {
    setState(() => _isEnding = true);
    final token = await AuthService().getToken();
    try {
      await http.post(
        Uri.parse('$apiBaseUrl/api/buses/${widget.busId}/release'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      debugPrint('Failed to release bus: $e');
    }
    
    if (mounted) {
      Navigator.pop(context);
    }
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
                Text('Route: ${widget.routeName}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isEnding ? null : _endTrip,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16)
                    ),
                    child: _isEnding 
                      ? const CircularProgressIndicator(color: Colors.red) 
                      : const Text('End Trip & Release Bus', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
