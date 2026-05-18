import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ticket_screen.dart';
import '../constants.dart';

class BusListScreen extends StatefulWidget {
  const BusListScreen({super.key});

  @override
  State<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends State<BusListScreen> {
  List<dynamic> activeBuses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBuses();
  }

  Future<void> _fetchBuses() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/api/buses'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          activeBuses = data['buses'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Buses')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (activeBuses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No active buses found.', textAlign: TextAlign.center),
                  ),
                ...activeBuses.map((bus) => ListTile(
                      title: Text('${bus['busName']} — ${bus['busNumber']}'),
                      subtitle: Text('Status: ${bus['status']} · Route: ${bus['route']?['routeName'] ?? 'N/A'}'),
                      trailing: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Track'),
                      ),
                    )),
                const Divider(),
                ListTile(
                  title: const Text('Book Ticket', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                  leading: const Icon(Icons.confirmation_number, color: Colors.teal),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TicketScreen()),
                  ),
                ),
              ],
            ),
    );
  }
}
