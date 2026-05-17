import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_logo.dart';
import '../services/auth_service.dart';
import 'info_screen.dart';
import 'login_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  AuthUser? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final u = await AuthService.getUser();
    if (mounted) setState(() => _user = u);
  }

  Future<void> _logout() async {
    await AuthService.logout();
    setState(() => _user = null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const BrandLogo(),
          const SizedBox(height: 8),
          const Text(
            'Botad city bus · Tracking only (no tickets yet)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (_user != null)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(_user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?'),
                ),
                title: Text(_user!.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(_user!.phone),
                trailing: TextButton(onPressed: _logout, child: const Text('Sign out')),
              ),
            ),
          const SizedBox(height: 16),
          _Section(
            title: 'Account (optional)',
            children: [
              if (_user == null)
                _Tile(
                  icon: Icons.login_rounded,
                  label: 'Sign in / Register',
                  subtitle: 'Future features ke liye',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen(returnToApp: true)),
                    );
                    _loadUser();
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Support',
            children: [
              _Tile(
                icon: Icons.help_outline_rounded,
                label: 'Help & FAQ',
                onTap: () => _openInfo(context, 'Help', InfoType.help),
              ),
              _Tile(
                icon: Icons.feedback_outlined,
                label: 'Feedback',
                onTap: () => _openInfo(context, 'Feedback', InfoType.feedback),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openInfo(BuildContext context, String title, InfoType type) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InfoScreen(title: title, type: type)),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Card(child: Column(children: children)),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
