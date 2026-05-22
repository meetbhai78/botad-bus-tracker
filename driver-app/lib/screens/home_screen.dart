import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'trip_screen.dart';
import 'qr_scanner_screen.dart';
import '../constants.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? user;
  List<dynamic> _buses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndBuses();
  }

  Future<void> _loadUserAndBuses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_json');
    if (raw != null) {
      setState(() => user = jsonDecode(raw) as Map<String, dynamic>);
    }
    await _fetchBuses();
  }

  Future<void> _fetchBuses() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/api/buses'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _buses = data['buses'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _assignBus(String busId) async {
    final token = await AuthService().getToken();
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/buses/$busId/assign'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bus selected successfully!')));
        _fetchBuses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Failed to assign bus')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error connecting to server')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Find if a bus is already assigned to this driver
    final userId = user?['id'] ?? user?['_id'];
    Map<String, dynamic>? assignedBus;
    for (final raw in _buses) {
      if (raw is! Map<String, dynamic>) continue;
      final b = raw;
      final d = b['driver'];
      if (d == null) continue;
      final did = d is Map ? (d['_id'] ?? d['id']) : d;
      if (did == userId || did?.toString() == userId?.toString()) {
        assignedBus = b;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Driver Home')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.blue.shade50,
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(user?['name'] ?? 'Driver', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(assignedBus != null 
                          ? 'Assigned: ${assignedBus['busNumber']} · ${assignedBus['route']?['routeName'] ?? 'Unknown'}'
                          : 'No bus assigned currently'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (assignedBus != null) ...[
                    FilledButton.icon(
                      onPressed: () async {
                        final token = await AuthService().getToken();
                        try {
                          final res = await http.post(
                            Uri.parse('$apiBaseUrl/api/trips/start'),
                            headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
                            body: jsonEncode({'busId': assignedBus['_id'], 'routeId': assignedBus['route']?['_id']})
                          );
                          final data = jsonDecode(res.body);
                          if (res.statusCode == 200 || res.statusCode == 201) {
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TripScreen(
                                  busId: assignedBus['_id'],
                                  routeName: assignedBus['route']?['routeName'] ?? 'Unknown Route',
                                  tripId: data['trip']['_id'],
                                ),
                              ),
                            ).then((_) => _fetchBuses());
                          } else {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Failed to start trip')));
                          }
                        } catch(e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error starting trip')));
                        }
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Trip'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const QRScannerScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan Passenger Ticket'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ] else ...[
                    const Text('Available Buses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buses.isEmpty
                          ? const Center(child: Text('No buses available in the system.'))
                          : RefreshIndicator(
                              onRefresh: _fetchBuses,
                              child: ListView.builder(
                                itemCount: _buses.length,
                                itemBuilder: (context, index) {
                                  final bus = _buses[index];
                                  final isAssignedToOther = bus['driver'] != null && 
                                    (bus['driver']['_id'] != userId && bus['driver']['id'] != userId);
                                  
                                  return Card(
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.directions_bus, 
                                        color: isAssignedToOther ? Colors.grey : Colors.green
                                      ),
                                      title: Text('${bus['busNumber']} (${bus['busName']})'),
                                      subtitle: Text('Route: ${bus['route']?['routeName'] ?? 'None'}'),
                                      trailing: isAssignedToOther
                                          ? const Text('Assigned', style: TextStyle(color: Colors.red))
                                          : OutlinedButton(
                                              onPressed: () => _assignBus(bus['_id']),
                                              child: const Text('Select'),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
