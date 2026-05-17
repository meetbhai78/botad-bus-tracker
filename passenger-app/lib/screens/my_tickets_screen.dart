import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  List<dynamic> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) {
      setState(() => _loading = false);
      return;
    }
    try {
      final headers = await AuthService.authHeaders();
      final response = await http.get(Uri.parse('$apiBaseUrl/api/tickets/my'), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _tickets = data['tickets'] ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My tickets')),
      body: FutureBuilder<bool>(
        future: AuthService.isLoggedIn(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data != true) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sign in to view your bookings'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen(returnToApp: true)),
                      );
                      _load();
                    },
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            );
          }
          if (_loading) return const Center(child: CircularProgressIndicator());
          if (_tickets.isEmpty) {
            return const Center(child: Text('No tickets yet', style: TextStyle(color: AppColors.textSecondary)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final t = _tickets[i];
              return Card(
                child: ListTile(
                  title: Text('${t['fromStop']} → ${t['toStop']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('₹${t['price']} · ${t['status']}'),
                  trailing: Text(
                    t['bookedAt'] != null ? DateTime.parse(t['bookedAt']).toLocal().toString().split(' ').first : '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
