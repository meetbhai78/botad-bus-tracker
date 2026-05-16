import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const BotadDriverApp());
}

class BotadDriverApp extends StatelessWidget {
  const BotadDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Botad Driver',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D9488)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
