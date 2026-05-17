import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum InfoType {
  bookingPolicy,
  cancellation,
  viewBooking,
  txnPassword,
  feedback,
  help,
  refund,
}

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key, required this.title, required this.type});

  final String title;
  final InfoType type;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(_icon, size: 56, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(_heading, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(_body, style: const TextStyle(fontSize: 15, height: 1.5)),
          if (type == InfoType.feedback) ...[
            const SizedBox(height: 24),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write your feedback...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you! Your feedback has been recorded.')),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ],
      ),
    );
  }

  IconData get _icon => switch (type) {
        InfoType.bookingPolicy => Icons.policy,
        InfoType.cancellation => Icons.cancel,
        InfoType.viewBooking => Icons.receipt_long,
        InfoType.txnPassword => Icons.vpn_key,
        InfoType.feedback => Icons.feedback,
        InfoType.help => Icons.support_agent,
        InfoType.refund => Icons.currency_exchange,
      };

  String get _heading => switch (type) {
        InfoType.bookingPolicy => 'Booking Policy',
        InfoType.cancellation => 'Cancel Your Ticket',
        InfoType.viewBooking => 'Your Bookings',
        InfoType.txnPassword => 'Transaction Password',
        InfoType.feedback => 'We value your opinion',
        InfoType.help => 'Help & Support',
        InfoType.refund => 'Refund Complaints',
      };

  String get _body => switch (type) {
        InfoType.bookingPolicy =>
          'Tickets can be booked up to 30 days in advance. Show your QR ticket to the conductor before boarding. Fares are fixed per route.',
        InfoType.cancellation =>
          'Tickets cancelled at least 2 hours before departure are eligible for a refund. Contact the bus stand counter or use this app with your ticket ID.',
        InfoType.viewBooking =>
          'Enter your mobile number at the counter to view past bookings. Online booking history will appear here in a future update.',
        InfoType.txnPassword =>
          'Use your registered mobile number to reset your transaction password via OTP. Visit Help & Support if you need assistance.',
        InfoType.feedback =>
          'Tell us about your travel experience on Botad city buses. Your suggestions help improve routes and timings.',
        InfoType.help =>
          'Developer: Meet Berani\nEmail: meetberani78@gmail.com\nAddress: Bhadravadi, Botad, Gujarat',
        InfoType.refund =>
          'For refund complaints, share your ticket number and travel date. Refunds are processed within 5–7 working days.',
      };
}
