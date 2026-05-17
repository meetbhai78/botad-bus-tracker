import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/socket_service.dart';
import '../services/stops_service.dart';
import '../theme/app_colors.dart';
import 'bus_list_screen.dart';
import 'search_buses_screen.dart';
import 'timetable_screen.dart';

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

  @override
  void initState() {
    super.initState();
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
            final lat = b['lat'] as double;
            final lng = b['lng'] as double;
            final busNumber = b['busNumber']?.toString() ?? 'Bus';
            final busName = b['busName']?.toString() ?? '';

            // Focus on target bus
            if (widget.targetBusId != null && b['busId']?.toString() == widget.targetBusId) {
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
    final routeData = busData['route'];
    final routeName = routeData?['routeName']?.toString() ?? 'N/A';
    
    // Attempt to extract stops from the route data
    // In our backend, route object contains 'stops' array if populated, but socket might only send basic route info.
    // If stops are missing, we just show the route name.
    
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
            Row(
              children: [
                const Icon(Icons.directions_bus, size: 30, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$busName ($busNumber)', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Route: $routeName', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Upcoming Stops:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'This bus stops at all major locations along the route. Tap "Search Route" for full timetable details.',
                style: TextStyle(color: Colors.black87),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  // Focus the camera on this bus
                  if (busData['lat'] != null && busData['lng'] != null) {
                    _mapController.move(LatLng(busData['lat'], busData['lng']), 16.0);
                  }
                },
                icon: const Icon(Icons.my_location, color: Colors.white),
                label: const Text('Track Bus', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
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
          urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=d39cWWFDlw1ibSbMysvD',
          userAgentPackageName: 'com.botad.passenger',
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
                    _MapAction(
                      icon: Icons.search_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchBusesScreen()),
                      ),
                    ),
                    _MapAction(
                      icon: Icons.schedule_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TimetableScreen()),
                      ),
                    ),
                    _MapAction(
                      icon: Icons.list_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BusListScreen()),
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

class _MapAction extends StatelessWidget {
  const _MapAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: AppColors.primary),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}
