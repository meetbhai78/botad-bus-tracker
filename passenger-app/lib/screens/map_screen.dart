import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/socket_service.dart';
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
  List<Marker> _markers = [];
  bool _hasFocusedOnTarget = false;

  @override
  void initState() {
    super.initState();
    _socket.onBuses = _updateMarkers;
    _socket.connect();
    if (widget.targetBusId != null) {
      Future.delayed(const Duration(milliseconds: 400), () {
        _socket.watchBus(widget.targetBusId!);
      });
    }
  }

  void _updateMarkers(List<dynamic> buses) {
    if (!mounted) return;
    setState(() {
      _markers = buses
          .where((b) => b['lat'] != null && b['lng'] != null)
          .map((b) {
            final lat = b['lat'] as double;
            final lng = b['lng'] as double;

            if (widget.targetBusId != null && b['busId']?.toString() == widget.targetBusId) {
              if (!_hasFocusedOnTarget) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  _mapController.move(LatLng(lat, lng), 16.0);
                });
                _hasFocusedOnTarget = true;
              }
            }

            final isTarget = widget.targetBusId != null && b['busId']?.toString() == widget.targetBusId;

            return Marker(
              point: LatLng(lat, lng),
              width: 50,
              height: 50,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Text(
                      b['busName']?.toString() ?? 'Bus',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(
                    Icons.directions_bus_rounded,
                    color: isTarget ? AppColors.accent : AppColors.primary,
                    size: 30,
                  ),
                ],
              ),
            );
          })
          .toList();
    });
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
        MarkerLayer(markers: _markers),
      ],
    );

    if (!widget.embedded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live map')),
        body: map,
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
