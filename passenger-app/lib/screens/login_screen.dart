import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_logo.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'app_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.returnToApp = false});

  final bool returnToApp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.login(_phone.text.trim(), _password.text);
      if (!mounted) return;
      if (widget.returnToApp) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Center(child: BrandLogo()),
              const SizedBox(height: 32),
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text('Sign in to book tickets and view your trips.', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Sign in'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterScreen(returnToApp: widget.returnToApp)),
                ),
                child: const Text('New here? Create account'),
              ),
              if (!widget.returnToApp) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AppShell()),
                  ),
                  child: const Text('Continue without account'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
