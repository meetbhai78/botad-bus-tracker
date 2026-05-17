import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import 'app_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.returnToApp = false});

  final bool returnToApp;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.register(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      );
      if (!mounted) return;
      if (widget.returnToApp) {
        Navigator.pop(context, true);
        Navigator.pop(context, true);
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AppShell()),
          (_) => false,
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
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Register as passenger for Botad city bus.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password (min 6)', border: OutlineInputBorder()),
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
                    : const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
