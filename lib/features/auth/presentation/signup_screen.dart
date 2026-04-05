import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/domain/entities/signup_request.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _handle = TextEditingController();
  final _email = TextEditingController();
  final _display = TextEditingController();
  final _bio = TextEditingController();
  final _password = TextEditingController();
  final _invite = TextEditingController();
  bool _validating = false;
  bool _inviteOk = false;
  String? _error;

  @override
  void dispose() {
    _handle.dispose();
    _email.dispose();
    _display.dispose();
    _bio.dispose();
    _password.dispose();
    _invite.dispose();
    super.dispose();
  }

  Future<void> _validateInvite() async {
    final code = _invite.text.trim();
    if (code.isEmpty) {
      setState(() {
        _inviteOk = false;
        _error = 'Enter invite code';
      });
      return;
    }
    setState(() => _validating = true);
    try {
      final ok = await ref.read(inviteUseCaseProvider).validateInviteCode(code);
      setState(() {
        _inviteOk = ok;
        _validating = false;
        _error = ok ? null : 'Invalid invite code';
      });
    } on Object catch (e) {
      setState(() {
        _validating = false;
        _inviteOk = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _signup() async {
    if (!_inviteOk) {
      setState(() => _error = 'Validate your invite code first');
      return;
    }
    final err = await ref.read(authNotifierProvider.notifier).signup(
          SignupRequest(
            handle: _handle.text.trim(),
            email: _email.text.trim(),
            displayName: _display.text.trim(),
            bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
            password: _password.text,
            inviteCode: _invite.text.trim(),
          ),
        );
    if (!mounted) {
      return;
    }
    if (err != null) {
      setState(() => _error = err);
    } else {
      context.go('/feed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_error != null)
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          TextField(
            controller: _invite,
            decoration: const InputDecoration(labelText: 'Invite code'),
          ),
          Row(
            children: [
              TextButton(
                onPressed: _validating ? null : _validateInvite,
                child: _validating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Validate code'),
              ),
              if (_inviteOk) const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
          TextField(
            controller: _handle,
            decoration: const InputDecoration(labelText: 'Handle'),
          ),
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _display,
            decoration: const InputDecoration(labelText: 'Display name'),
          ),
          TextField(
            controller: _bio,
            decoration: const InputDecoration(labelText: 'Bio (optional)'),
          ),
          TextField(
            controller: _password,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _signup,
            child: const Text('Sign up'),
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Back to login'),
          ),
        ],
      ),
    );
  }
}
