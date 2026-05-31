import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          if (type == InfoType.help) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary,
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meet Berani',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Lead Developer',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1),
                    _ContactRow(
                      icon: Icons.email_rounded,
                      label: 'Email',
                      value: 'meetberani78@gmail.com',
                      onTap: () {
                        Clipboard.setData(
                          const ClipboardData(text: 'meetberani78@gmail.com'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Email copied to clipboard! 🚀')),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const _ContactRow(
                      icon: Icons.location_on_rounded,
                      label: 'Address',
                      value: 'Bhadravadi, Botad, Gujarat',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Contact & Deployment Card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    AppColors.accent.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.rocket_launch_rounded,
                          color: AppColors.accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Deploy in Your City / College',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Kya aap is modern real-time bus tracking aur digital ticketing system ko apne school, college, corporate fleet, ya kisi dusre city/route ke liye deploy karna chahte hain?',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Hum collab karne aur white-label setup ke liye completely active hain. Direct connect karein!',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          const ClipboardData(text: 'meetberani78@gmail.com'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Email ID (meetberani78@gmail.com) copied to clipboard! 🚀',
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.email_outlined, size: 20),
                      label: const Text(
                        'Contact for Collaboration',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(_body, style: const TextStyle(fontSize: 15, height: 1.5)),
          ],
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

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          const Icon(
            Icons.copy_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: body,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: body,
    );
  }
}
