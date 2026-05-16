import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});

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
    setState(() {
      _isLoading = true;
      qrData = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/tickets/book'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fromStop': fromStop,
          'toStop': toStop,
          'price': price,
          // 'trip': 'trip_id_here' // If a specific trip needs to be selected
        }),
      );

      final result = jsonDecode(response.body);
      
      setState(() {
        if (response.statusCode == 201 || response.statusCode == 200) {
          // If the backend returns a QR Code string (e.g. base64 or ticket ID)
          qrData = result['data']?['qrCode'] ?? result['ticketId'] ?? 'ticket:${fromStop}->${toStop}:$price';
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket Booked Successfully!'), backgroundColor: Colors.green),
          );
        } else {
          // Mock QR data if backend auth fails since passenger login isn't forced yet
          qrData = 'ticket_mock_${DateTime.now().millisecondsSinceEpoch}';
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Using Mock Ticket (Guest Mode)'), backgroundColor: Colors.orange),
          );
        }
      });
    } catch (e) {
      setState(() {
        qrData = 'ticket_mock_${DateTime.now().millisecondsSinceEpoch}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network Error - Generated Offline Ticket'), backgroundColor: Colors.orange),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book ticket')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: fromStop,
              decoration: const InputDecoration(labelText: 'From'),
              items: ['Botad Bus Stand', 'Botad Market', 'Botad College']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => fromStop = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: toStop,
              decoration: const InputDecoration(labelText: 'To'),
              items: ['Botad College', 'Railway Station', 'Botad Hospital']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => toStop = v),
            ),
            const SizedBox(height: 16),
            Text('Price: ₹$price', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isLoading ? null : _bookTicket,
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Book ticket'),
            ),
            if (qrData != null) ...[
              const SizedBox(height: 24),
              Center(child: QrImageView(data: qrData!, size: 200)),
              const SizedBox(height: 8),
              const Text('Show QR to driver', textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
