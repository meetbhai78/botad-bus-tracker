import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const BotadPassengerApp());
}

class BotadPassengerApp extends StatelessWidget {
  const BotadPassengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Botad Bus Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: FutureBuilder<bool>(
        future: AuthService.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.data == true) {
            return const AppShell();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
