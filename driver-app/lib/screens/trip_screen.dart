import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../services/gps_service.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../constants.dart';

/// Active trip — GPS + Socket broadcast every ~3 sec
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
  double _speed = 0.0;
  StreamSubscription? _gpsSub;
  Timer? _emitTimer;
  bool _mapReady = false;
  bool _isEnding = false;

  // Previous position and timestamp for manual speed calculation
  LatLng? _prevPosition;
  DateTime? _prevTime;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  // Haversine formula to compute distance in meters between two coordinates
  double _calculateDistance(LatLng p1, LatLng p2) {
    const r = 6371000.0; // Earth radius in meters
    final lat1 = p1.latitude * math.pi / 180;
    final lat2 = p2.latitude * math.pi / 180;
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180;
    final dLng = (p2.longitude - p1.longitude) * math.pi / 180;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c; // meters
  }

  Future<void> _startTracking() async {
    if (!await _gps.ensurePermission()) return;
    final token = await AuthService().getToken();
    if (token != null) _socket.connect(token);

    _gpsSub = _gps.getLocationStream().listen((pos) {
      if (!mounted) return;

      final currentPos = LatLng(pos.latitude, pos.longitude);
      final currentTime = DateTime.now();
      double calculatedSpeed = 0.0;

      if (_prevPosition != null && _prevTime != null) {
        final distance = _calculateDistance(_prevPosition!, currentPos);
        final timeDiffSec = currentTime.difference(_prevTime!).inMilliseconds / 1000.0;

        if (timeDiffSec > 0.5) {
          // Speed in km/h = (meters / seconds) * 3.6
          calculatedSpeed = (distance / timeDiffSec) * 3.6;

          // Filter outliers / GPS jitter jumps
          if (calculatedSpeed > 100.0) {
            calculatedSpeed = _speed; // Maintain previous speed
          } else if (distance < 1.5) {
            calculatedSpeed = 0.0; // Stationary drift filter
          }
        }
      } else {
        // Fallback to standard GPS speed on startup
        calculatedSpeed = pos.speed > 0 ? pos.speed * 3.6 : 0.0;
      }

      _prevPosition = currentPos;
      _prevTime = currentTime;

      setState(() {
        _position = currentPos;
        // Apply smoothing filter: 70% current calculated, 30% previous speed
        _speed = (_speed == 0.0) ? calculatedSpeed : (0.7 * calculatedSpeed + 0.3 * _speed);
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
      if (widget.tripId != null) {
        await http.put(
          Uri.parse('$apiBaseUrl/api/trips/${widget.tripId}/end'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }

      await http.post(
        Uri.parse('$apiBaseUrl/api/buses/${widget.busId}/release'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      debugPrint('Failed to end trip: $e');
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showEndTripConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 8),
            Text('End Trip?'),
          ],
        ),
        content: const Text(
          'This will stop broadcasting your live coordinates to passengers and release the bus assignment. Are you sure?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _endTrip();
            },
            child: const Text('End & Release'),
          ),
        ],
      ),
    );
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Active Trip tracking',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: _showEndTripConfirmation,
        ),
      ),
      body: Column(
        children: [
          // Live Map view
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _position,
                initialZoom: 15.5,
                onMapReady: () {
                  setState(() {
                    _mapReady = true;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: mapTileUrl,
                  userAgentPackageName: 'com.botad.driver',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _position,
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: const Icon(
                          Icons.navigation_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Gorgeous Dashboard HUD speedometer card
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Speedometer Circular-look Layout
                    Row(
                      children: [
                        // Giant speedometer bubble
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _speed.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              const Text(
                                'KM/H',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        
                        // Trip status information
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Route: ${widget.routeName}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Live GPS Broadcasting Active',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Frequency: ~3 seconds update',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Stop Trip Action Trigger Button
                    SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: _isEnding ? null : _showEndTripConfirmation,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error, width: 1.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _isEnding
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: AppColors.error, strokeWidth: 2),
                              )
                            : const Icon(Icons.stop_circle_rounded, size: 22),
                        label: Text(
                          _isEnding ? 'ENDING TRIP…' : 'END TRIP & RELEASE BUS',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
