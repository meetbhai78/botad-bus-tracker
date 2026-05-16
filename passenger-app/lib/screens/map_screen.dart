import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/socket_service.dart';
import 'bus_list_screen.dart';
import 'search_buses_screen.dart';
import 'timetable_screen.dart';

class MapScreen extends StatefulWidget {
  final String? targetBusId;
  const MapScreen({super.key, this.targetBusId});

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
  }

  void _updateMarkers(List<dynamic> buses) {
    if (!mounted) return;
    setState(() {
      _markers = buses
          .where((b) => b['lat'] != null && b['lng'] != null)
          .map((b) {
            final lat = b['lat'] as double;
            final lng = b['lng'] as double;
            
            // Auto-focus logic if a specific bus was searched
            if (widget.targetBusId != null && b['busId'] == widget.targetBusId) {
              if (!_hasFocusedOnTarget) {
                // Delay slightly to ensure map is ready
                Future.delayed(const Duration(milliseconds: 500), () {
                  _mapController.move(LatLng(lat, lng), 16.0);
                });
                _hasFocusedOnTarget = true;
              }
            }

            final isTarget = widget.targetBusId == b['busId'];

            return Marker(
              point: LatLng(lat, lng),
              width: 50,
              height: 50,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Text(
                      b['busName']?.toString() ?? 'Bus',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(
                    Icons.directions_bus,
                    color: isTarget ? Colors.green : Colors.blue,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Botad Bus Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule),
            tooltip: 'Timetable & Stops',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TimetableScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Routes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchBusesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'All Active Buses',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BusListScreen()),
            ),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _center,
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            // MapTiler Vector/Raster URL using the provided key
            urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=d39cWWFDlw1ibSbMysvD',
            userAgentPackageName: 'com.botad.passenger',
          ),
          MarkerLayer(
            markers: _markers,
          ),
        ],
      ),
    );
  }
}
