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

  Future<void> _fetchRoutes({bool viewAll = false}) async {
    setState(() {
      isLoading = true;
      hasSearched = true;
    });

    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/api/routes'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> routes = data['routes'] ?? [];

        if (!viewAll && (_fromController.text.isNotEmpty || _toController.text.isNotEmpty)) {
          final fromText = _fromController.text.trim().toLowerCase();
          final toText = _toController.text.trim().toLowerCase();
          
          routes = routes.where((r) {
            final stops = r['stops'] as List<dynamic>? ?? [];
            int fromIdx = -1;
            int toIdx = -1;
            
            for (int i = 0; i < stops.length; i++) {
              final stopName = stops[i]['name'].toString().toLowerCase();
              if (fromText.isNotEmpty && stopName.contains(fromText)) fromIdx = i;
              if (toText.isNotEmpty && stopName.contains(toText)) toIdx = i;
            }
            
            if (fromText.isNotEmpty && toText.isNotEmpty) return fromIdx != -1 && toIdx != -1 && fromIdx < toIdx;
            if (fromText.isNotEmpty) return fromIdx != -1;
            if (toText.isNotEmpty) return toIdx != -1;
            return false;
          }).toList();
        }
        setState(() => timetableList = routes);
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
      appBar: AppBar(title: const Text('Routes & Timetable')),
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
                        labelText: 'From stop (optional)',
                        prefixIcon: Icon(Icons.trip_origin, color: AppColors.primary),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _toController,
                      decoration: const InputDecoration(
                        labelText: 'To stop (optional)',
                        prefixIcon: Icon(Icons.place, color: AppColors.accent),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading ? null : () => _fetchRoutes(viewAll: true),
                            child: const Text('View All Routes'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: isLoading ? null : () => _fetchRoutes(viewAll: false),
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Search'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: !hasSearched
                  ? const Center(child: Text('Search or view all routes', style: TextStyle(color: AppColors.textSecondary)))
                  : timetableList.isEmpty
                      ? const Center(child: Text('No routes found.'))
                      : ListView.builder(
                          itemCount: timetableList.length,
                          itemBuilder: (context, index) {
                            final route = timetableList[index];
                            final stops = route['stops'] as List<dynamic>? ?? [];
                            final distance = route['totalDistance'] ?? 0;
                            final time = route['totalTime'] ?? 0;
                            
                            return Card(
                              child: ExpansionTile(
                                leading: const CircleAvatar(child: Icon(Icons.route)),
                                title: Text(
                                  route['routeName'] ?? 'Unknown Route',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text('${route['routeNumber']} • $distance km • ~${time} mins'),
                                children: stops
                                    .map(
                                      (s) => ListTile(
                                        dense: true,
                                        leading: const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                        title: Text(s['name']?.toString() ?? ''),
                                        trailing: Text('+${s['estimatedTime'] ?? 0} min'),
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
