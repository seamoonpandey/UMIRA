import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/umira_button.dart';
import '../../../shared/widgets/umira_text_field.dart';
import '../providers/auth_provider.dart';

class SignUpView extends ConsumerStatefulWidget {
  const SignUpView({super.key});
  @override
  ConsumerState<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends ConsumerState<SignUpView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _consent = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
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
              UmiraTextField(controller: _email, label: 'Email'),
              const SizedBox(height: 16),
              UmiraTextField(
                  controller: _password,
                  label: 'Password (8+ chars)',
                  obscure: true,),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _consent,
                onChanged: (v) => setState(() => _consent = v ?? false),
                title: const Text(
                  'I am 16+ and I understand UMIRA is not a medical or diagnostic tool.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              UmiraButton(
                label: _busy ? 'Creating...' : 'Create account',
                primary: true,
                onPressed: _busy || !_consent ? null : _submit,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/sign-in'),
                child: const Text('I already have an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_password.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authStateProvider.notifier)
          .signUp(_email.text.trim(), _password.text);
      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _error = 'Sign-up failed. Try a different email.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
