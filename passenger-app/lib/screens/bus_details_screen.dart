import 'package:flutter/material.dart';
import '../services/socket_service.dart';

class BusDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> bus;

  const BusDetailsScreen({super.key, required this.bus});

  @override
  State<BusDetailsScreen> createState() => _BusDetailsScreenState();
}

class _BusDetailsScreenState extends State<BusDetailsScreen> {
  final _socket = SocketService();
  final Map<String, int> _etas = {};

  @override
  void initState() {
    super.initState();
    _socket.connect();
    
    final route = widget.bus['route'];
    final stops = route != null ? (route['stops'] as List<dynamic>) : [];
    
    // Watch all stops for this bus
    for (final stop in stops) {
      if (stop['_id'] != null) {
        _socket.watchStop(stop['_id']);
      }
    }
    
    _socket.onStopEta = (data) {
      if (!mounted) return;
      if (data['busId'] == widget.bus['_id'] && data['stopId'] != null) {
        setState(() {
          _etas[data['stopId']] = data['etaMinutes'] as int;
        });
      }
    };
  }

  @override
  void dispose() {
    _socket.onStopEta = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.bus['route'];
    final stops = route != null ? (route['stops'] as List<dynamic>) : [];

    return Scaffold(
      appBar: AppBar(title: Text('${widget.bus['busName']} - Route Info')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bus: ${widget.bus['busNumber']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text('Status: ${widget.bus['status'].toString().toUpperCase()}', style: TextStyle(color: widget.bus['status'] == 'active' ? Colors.green : Colors.orange)),
                    const SizedBox(height: 4),
                    Text('Seats Available: ${widget.bus['capacity'] ?? 50}'),
                  ],
                ),
                const Icon(Icons.directions_bus, size: 48, color: Colors.teal),
              ],
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Stops Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: stops.isEmpty
                ? const Center(child: Text('No stops mapped for this route.'))
                : ListView.builder(
                    itemCount: stops.length,
                    itemBuilder: (context, index) {
                      final stop = stops[index];
                      final stopId = stop['_id'];
                      final etaMin = _etas[stopId];
                      
                      String etaText = etaMin != null ? 'ETA: $etaMin mins' : 'Calculating ETA...';
                      
                      return ListTile(
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.circle, size: 12, color: Colors.teal),
                            if (index < stops.length - 1)
                              Container(width: 2, height: 24, color: Colors.teal),
                          ],
                        ),
                        title: Text(stop['name'] ?? 'Unknown Stop', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(etaText, style: TextStyle(color: etaMin != null ? Colors.blue.shade700 : Colors.grey)),
                        trailing: const Icon(Icons.map, color: Colors.grey),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
