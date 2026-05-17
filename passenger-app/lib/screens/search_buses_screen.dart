import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import 'map_screen.dart';

class SearchBusesScreen extends StatefulWidget {
  const SearchBusesScreen({super.key});

  @override
  State<SearchBusesScreen> createState() => _SearchBusesScreenState();
}

class _SearchBusesScreenState extends State<SearchBusesScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  
  List<dynamic> searchResults = [];
  bool isLoading = false;
  bool hasSearched = false;

  Future<void> _searchBuses() async {
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
      final response = await http.get(Uri.parse('$apiBaseUrl/api/buses?from=$fromQuery&to=$toQuery'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          searchResults = data['buses'] ?? [];
        });
      } else {
        setState(() => searchResults = []);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search route')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Box UI
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _fromController,
                      decoration: const InputDecoration(
                        labelText: 'From (e.g. Botad Stand)',
                        prefixIcon: Icon(Icons.my_location, color: Colors.blue),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _toController,
                      decoration: const InputDecoration(
                        labelText: 'To (e.g. College)',
                        prefixIcon: Icon(Icons.location_on, color: Colors.red),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isLoading ? null : _searchBuses,
                        icon: const Icon(Icons.search),
                        label: isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Search Buses'),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Results UI
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : !hasSearched
                      ? const Center(child: Text('Enter stops to find buses', style: TextStyle(color: Colors.grey)))
                      : searchResults.isEmpty
                          ? const Center(child: Text('No buses found for this route', style: TextStyle(fontWeight: FontWeight.bold)))
                          : ListView.builder(
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                final bus = searchResults[index];
                                return Card(
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.teal,
                                      child: Icon(Icons.directions_bus, color: Colors.white),
                                    ),
                                    title: Text('${bus['busName']} — ${bus['busNumber']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('Status: ${bus['status']}\nRoute: ${bus['route']?['routeName'] ?? 'N/A'}'),
                                    isThreeLine: true,
                                    trailing: FilledButton.tonal(
                                      onPressed: () {
                                        // Navigate to MapScreen and focus on this bus
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => MapScreen(targetBusId: bus['_id']),
                                          ),
                                        );
                                      },
                                      child: const Text('Track Live'),
                                    ),
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
