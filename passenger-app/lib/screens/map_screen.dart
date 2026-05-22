import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/socket_service.dart';
import '../services/stops_service.dart';
import '../theme/app_colors.dart';
import 'timetable_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.targetBusId, this.embedded = false});

  final String? targetBusId;
  final bool embedded;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _socket = PassengerSocketService();
  final LatLng _center = const LatLng(22.1647, 71.6661);
  final MapController _mapController = MapController();
  
  List<Marker> _busMarkers = [];
  List<Marker> _stopMarkers = [];
  List<BusStop> _allStops = [];
  
  BusStop? _selectedDestination;
  bool _hasFocusedOnTarget = false;
  bool _notifiedArrival = false;
  
  List<LatLng> _selectedRoutePolyline = [];
  String? _trackedBusId;

  // Simple OSRM Polyline Decoder (Precision 5)
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  Future<void> _fetchRoutePolyline(String routeId) async {
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/api/routes/$routeId'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] && data['route'] != null) {
          final route = data['route'];
          List<LatLng> points = [];
          
          // 1. Try decoding OSRM polyline first if present
          if (route['polyline'] != null && route['polyline'].toString().isNotEmpty) {
            try {
              points = _decodePolyline(route['polyline'] as String);
            } catch (e) {
              debugPrint('Decoding polyline failed: $e');
            }
          }
          
          // 2. Fallback to connecting stops in order if polyline was missing or failed to decode
          if (points.isEmpty && route['stops'] != null && route['stops'] is List) {
            final List<dynamic> stopsList = List.from(route['stops']);
            stopsList.sort((a, b) {
              final int orderA = a['order'] is int ? a['order'] : 0;
              final int orderB = b['order'] is int ? b['order'] : 0;
              return orderA.compareTo(orderB);
            });
            
            for (var stop in stopsList) {
              if (stop['lat'] != null && stop['lng'] != null) {
                points.add(LatLng((stop['lat'] as num).toDouble(), (stop['lng'] as num).toDouble()));
              }
            }
            debugPrint('Polyline fallback loaded with ${points.length} stops.');
          }

          if (mounted) {
            setState(() {
              _selectedRoutePolyline = points;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Polyline error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _trackedBusId = widget.targetBusId;
    _loadStops();
    _socket.onBuses = _updateBuses;
    _socket.connect();
    if (widget.targetBusId != null) {
      Future.delayed(const Duration(milliseconds: 400), () {
        _socket.watchBus(widget.targetBusId!);
      });
    }
  }

  Future<void> _loadStops() async {
    try {
      final stops = await StopsService.fetchStops();
      if (!mounted) return;
      setState(() {
        _allStops = stops;
        _buildStopMarkers();
      });
    } catch (e) {
      debugPrint('Error loading stops: $e');
    }
  }

  void _buildStopMarkers() {
    _stopMarkers = _allStops.map((stop) {
      final isDest = _selectedDestination?.id == stop.id;
      return Marker(
        point: LatLng(stop.lat, stop.lng),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _onStopTapped(stop),
          child: Column(
            children: [
              Icon(
                isDest ? Icons.flag_rounded : Icons.location_on_rounded,
                color: isDest ? Colors.red : Colors.blueGrey,
                size: isDest ? 30 : 24,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _onStopTapped(BusStop stop) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stop: ${stop.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Would you like to set this stop as your destination? We will notify you when a bus is arriving.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() {
                    _selectedDestination = stop;
                    _notifiedArrival = false;
                    _buildStopMarkers();
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Destination set to ${stop.name}. You will be notified when a bus is near.')),
                  );
                },
                child: const Text('Set as Destination', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TimetableScreen(initialFromStop: stop.name),
                    ),
                  );
                },
                child: const Text('View Timetable for this Stop', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateBuses(List<dynamic> buses) {
    if (!mounted) return;
    setState(() {
      _busMarkers = buses
          .where((b) => b['lat'] != null && b['lng'] != null)
          .map((b) {
            final lat = (b['lat'] as num).toDouble();
            final lng = (b['lng'] as num).toDouble();
            final busNumber = b['busNumber']?.toString() ?? 'Bus';

            // Focus on target bus or live follow tracked bus
            final isTracked = _trackedBusId != null && b['busId']?.toString() == _trackedBusId;
            if (isTracked) {
              _mapController.move(LatLng(lat, lng), _mapController.camera.zoom);
            } else if (widget.targetBusId != null && b['busId']?.toString() == widget.targetBusId) {
              if (!_hasFocusedOnTarget) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  _mapController.move(LatLng(lat, lng), 16.0);
                });
                _hasFocusedOnTarget = true;
              }
            }

            // Check distance to destination
            if (_selectedDestination != null && !_notifiedArrival) {
              final distance = const Distance().as(
                LengthUnit.Meter,
                LatLng(lat, lng),
                LatLng(_selectedDestination!.lat, _selectedDestination!.lng),
              );
              if (distance < 500) { // within 500 meters
                _notifiedArrival = true;
                _showArrivalNotification(busNumber, _selectedDestination!.name);
              }
            }

            final isTarget = widget.targetBusId != null && b['busId']?.toString() == widget.targetBusId;

            return Marker(
              point: LatLng(lat, lng),
              width: 80,
              height: 60,
              child: GestureDetector(
                onTap: () => _onBusTapped(b),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isTarget ? AppColors.accent : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Text(
                        busNumber,
                        style: TextStyle(
                          fontSize: 11, 
                          fontWeight: FontWeight.bold,
                          color: isTarget ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Icon(
                      Icons.directions_bus_rounded,
                      color: isTarget ? AppColors.accent : AppColors.primary,
                      size: 32,
                    ),
                  ],
                ),
              ),
            );
          })
          .toList();
    });
  }

  void _onBusTapped(dynamic busData) {
    final busName = busData['busName']?.toString() ?? 'Bus';
    final busNumber = busData['busNumber']?.toString() ?? '';
    
    // Parse route details defensively
    final routeData = busData['route'];
    String routeName = 'N/A';
    String? routeId = busData['routeId']?.toString();
    
    if (routeData != null) {
      if (routeData is Map) {
        routeName = routeData['routeName']?.toString() ?? 'N/A';
        routeId ??= routeData['_id']?.toString();
      } else if (routeData is String) {
        routeId ??= routeData;
      }
    }
    
    final busId = busData['busId']?.toString();
    
    setState(() {
      _trackedBusId = busId; // Immediately track it when tapped!
      if (routeId != null) {
        _fetchRoutePolyline(routeId);
      } else {
        _selectedRoutePolyline = [];
      }
    });

    if (busData['lat'] != null && busData['lng'] != null) {
      _mapController.move(LatLng((busData['lat'] as num).toDouble(), (busData['lng'] as num).toDouble()), 15.5);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 8,
      barrierColor: Colors.black.withValues(alpha: 0.1), // Light barrier so map is visible
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isCurrentlyTracking = _trackedBusId == busId;
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.directions_bus_rounded, size: 28, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$busName ($busNumber)',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.route_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Route: $routeName',
                                    style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: isCurrentlyTracking ? AppColors.primary : AppColors.border,
                              width: 1.5,
                            ),
                            backgroundColor: isCurrentlyTracking ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            setState(() {
                              if (isCurrentlyTracking) {
                                _trackedBusId = null; // Turn off live auto-follow tracking
                              } else {
                                _trackedBusId = busId; // Turn on live auto-follow tracking
                                // Focus instantly
                                if (busData['lat'] != null && busData['lng'] != null) {
                                  _mapController.move(LatLng((busData['lat'] as num).toDouble(), (busData['lng'] as num).toDouble()), 16.0);
                                }
                              }
                            });
                            // Update internal dialog state
                            setModalState(() {});
                          },
                          icon: Icon(
                            isCurrentlyTracking ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                            color: isCurrentlyTracking ? AppColors.primary : AppColors.textSecondary,
                          ),
                          label: Text(
                            isCurrentlyTracking ? 'Auto-Follow Active' : 'Auto-Follow',
                            style: TextStyle(
                              color: isCurrentlyTracking ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TimetableScreen(initialFromStop: routeName != 'N/A' ? routeName : null),
                              ),
                            );
                          },
                          icon: const Icon(Icons.schedule_rounded, color: Colors.white),
                          label: const Text(
                            'Route Details',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showArrivalNotification(String busNumber, String stopName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: AppColors.accent, size: 28),
            SizedBox(width: 8),
            Text('Bus Arriving!'),
          ],
        ),
        content: Text('Bus $busNumber is arriving soon at $stopName! Be ready to board.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: _center, initialZoom: 14.0),
      children: [
        TileLayer(
          urlTemplate: mapTileUrl,
          userAgentPackageName: 'com.botad.passenger',
        ),
        if (_selectedRoutePolyline.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _selectedRoutePolyline,
                strokeWidth: 6.0,
                color: const Color(0xFF2563EB).withValues(alpha: 0.8),
                isDotted: false,
              ),
            ],
          ),
        MarkerLayer(markers: _stopMarkers),
        MarkerLayer(markers: _busMarkers),
      ],
    );

    if (!widget.embedded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live map')),
        body: Stack(
          children: [
            map,
            if (_selectedDestination != null)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.flag, color: Colors.red),
                    title: const Text('Destination Set', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(_selectedDestination!.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedDestination = null;
                          _buildStopMarkers();
                        });
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Stack(
        children: [
          map,
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(14),
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.map_rounded, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Live buses · Botad',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedDestination != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.flag, color: Colors.red),
                  title: const Text('Destination Set', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_selectedDestination!.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedDestination = null;
                        _buildStopMarkers();
                      });
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
