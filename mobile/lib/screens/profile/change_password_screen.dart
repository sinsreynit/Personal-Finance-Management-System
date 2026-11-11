import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

// US-005 Change Password
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (auth.error != null)
                Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(auth.error!, style: const TextStyle(color: Colors.red))),
              TextFormField(controller: _current, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
              const SizedBox(height: 16),
              TextFormField(controller: _next, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
              const SizedBox(height: 16),
              TextFormField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password')),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: auth.loading
                    ? null
                    : () async {
                        final ok = await auth.changePassword(_current.text, _next.text, _confirm.text);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated.')));
                          Navigator.pop(context);
                        }
                      },
                child: const Text('Update password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
