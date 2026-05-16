import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import 'bus_details_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  
  List<dynamic> timetableList = [];
  bool isLoading = false;
  bool hasSearched = false;

  Future<void> _fetchTimetable() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both From and To stops.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      hasSearched = true;
    });

    try {
      final fromQuery = Uri.encodeComponent(_fromController.text.trim());
      final toQuery = Uri.encodeComponent(_toController.text.trim());
      
      // Re-using the buses endpoint which populates routes, 
      // but ideally we'd fetch Trips here for scheduled times.
      final response = await http.get(Uri.parse('$apiBaseUrl/api/buses?from=$fromQuery&to=$toQuery'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          timetableList = data['buses'] ?? [];
        });
      } else {
        setState(() => timetableList = []);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GSRTC-style Timetable')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _fromController,
                      decoration: const InputDecoration(labelText: 'Source Stop', prefixIcon: Icon(Icons.trip_origin), border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _toController,
                      decoration: const InputDecoration(labelText: 'Destination Stop', prefixIcon: Icon(Icons.place), border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isLoading ? null : _fetchTimetable,
                        child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('View Time Table'),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : !hasSearched
                      ? const Center(child: Text('Search for a route schedule'))
                      : timetableList.isEmpty
                          ? const Center(child: Text('No scheduled buses found.'))
                          : ListView.builder(
                              itemCount: timetableList.length,
                              itemBuilder: (context, index) {
                                final bus = timetableList[index];
                                return Card(
                                  child: ListTile(
                                    leading: const CircleAvatar(child: Icon(Icons.schedule)),
                                    title: Text('${bus['busName']} - ${bus['busNumber']}'),
                                    subtitle: Text('Status: ${bus['status'].toString().toUpperCase()}\nSeats available: ${bus['capacity'] ?? 50}'),
                                    isThreeLine: true,
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => BusDetailsScreen(bus: bus)),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
