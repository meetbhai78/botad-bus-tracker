import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import '../theme/app_colors.dart';
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key, this.initialFromStop});

  final String? initialFromStop;

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  List<dynamic> timetableList = [];
  bool isLoading = false;
  bool hasSearched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFromStop != null) {
      _fromController.text = widget.initialFromStop!;
    }
  }

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
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/timetable/search?from=$fromQuery&to=$toQuery'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => timetableList = data['timetables'] ?? []);
      } else {
        setState(() => timetableList = []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timetable')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _fromController,
                      decoration: const InputDecoration(
                        labelText: 'From stop',
                        prefixIcon: Icon(Icons.trip_origin, color: AppColors.primary),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _toController,
                      decoration: const InputDecoration(
                        labelText: 'To stop',
                        prefixIcon: Icon(Icons.place, color: AppColors.accent),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isLoading ? null : _fetchTimetable,
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('View timetable'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: !hasSearched
                  ? const Center(child: Text('Search schedule by stops', style: TextStyle(color: AppColors.textSecondary)))
                  : timetableList.isEmpty
                      ? const Center(child: Text('No timetable found for this route.'))
                      : ListView.builder(
                          itemCount: timetableList.length,
                          itemBuilder: (context, index) {
                            final entry = timetableList[index];
                            final route = entry['route'];
                            return Card(
                              child: ExpansionTile(
                                leading: const CircleAvatar(child: Icon(Icons.schedule)),
                                title: Text(
                                  '${entry['departureTime']} — ${route?['routeName'] ?? 'Route'}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(entry['direction']?.toString() ?? route?['routeNumber'] ?? ''),
                                children: (entry['schedule'] as List<dynamic>? ?? [])
                                    .map(
                                      (s) => ListTile(
                                        dense: true,
                                        title: Text(s['stopName']?.toString() ?? ''),
                                        trailing: Text(s['arrivalTime']?.toString() ?? ''),
                                      ),
                                    )
                                    .toList(),
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
