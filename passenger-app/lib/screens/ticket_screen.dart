import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  String? fromStop = 'Botad Bus Stand';
  String? toStop = 'Botad College';
  String? qrData;
  static const price = 15;
  bool _isLoading = false;

  Future<void> _bookTicket() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) {
      if (!mounted) return;
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen(returnToApp: true)),
      );
      if (ok != true && !await AuthService.isLoggedIn()) return;
    }

    setState(() {
      _isLoading = true;
      qrData = null;
    });

    try {
      final headers = await AuthService.authHeaders();
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/tickets/book-simple'),
        headers: headers,
        body: jsonEncode({
          'fromStop': fromStop,
          'toStop': toStop,
          'price': price,
        }),
      );

      final result = jsonDecode(response.body);

      if (!mounted) return;
      if (response.statusCode == 201 || response.statusCode == 200) {
        final raw = result['data']?['qrCode']?.toString() ??
            result['ticket']?['qrCode']?.toString();
        if (raw == null || raw.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid response from server'), backgroundColor: Colors.redAccent),
          );
        } else {
          setState(() => qrData = raw);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket booked!'), backgroundColor: AppColors.primary),
          );
        }
      } else {
        final msg = result['message']?.toString() ?? 'Could not book ticket';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        qrData = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.embedded) ...[
            Text(
              'Book ticket',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text('Quick QR for your ride', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: fromStop,
                    decoration: const InputDecoration(
                      labelText: 'From',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Botad Bus Stand', 'Botad Market', 'Botad College']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => fromStop = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: toStop,
                    decoration: const InputDecoration(
                      labelText: 'To',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Botad College', 'Railway Station', 'Botad Hospital']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => toStop = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('₹$price', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isLoading ? null : _bookTicket,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Get ticket'),
          ),
          if (qrData != null) ...[
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    QrImageView(data: qrData!, size: 200),
                    const SizedBox(height: 12),
                    const Text('Show this QR to the driver', textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.embedded) {
      return SafeArea(child: content);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tickets')),
      body: content,
    );
  }
}
