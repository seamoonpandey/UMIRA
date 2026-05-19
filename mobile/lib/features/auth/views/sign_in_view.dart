import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/umira_button.dart';
import '../../../shared/widgets/umira_text_field.dart';
import '../providers/auth_provider.dart';

class SignInView extends ConsumerStatefulWidget {
  const SignInView({super.key});
  @override
  ConsumerState<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends ConsumerState<SignInView> {
  final _email = TextEditingController(text: 'demo@umira.app');
  final _password = TextEditingController(text: 'DemoPass!234');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UmiraTextField(
                  controller: _email,
                  label: 'Email',
                  autofillHints: const [AutofillHints.email],),
              const SizedBox(height: 16),
              UmiraTextField(
                  controller: _password,
                  label: 'Password',
                  obscure: true,
                  autofillHints: const [AutofillHints.password],),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              UmiraButton(
                label: _busy ? 'Signing in...' : 'Sign in',
                primary: true,
                onPressed: _busy ? null : _submit,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/sign-up'),
                child: const Text('Create an account instead'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authStateProvider.notifier)
          .signIn(_email.text.trim(), _password.text);
      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _error = 'Sign-in failed. Check your email and password.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
