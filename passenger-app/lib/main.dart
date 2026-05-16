import 'package:flutter/material.dart';
import 'screens/map_screen.dart';

void main() => runApp(const BotadPassengerApp());

class BotadPassengerApp extends StatelessWidget {
  const BotadPassengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Botad Bus',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF0D9488), useMaterial3: true),
      home: const MapScreen(),
    );
  }
}
