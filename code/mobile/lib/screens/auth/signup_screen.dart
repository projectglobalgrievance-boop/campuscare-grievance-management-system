import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _dept = TextEditingController();
  String _role = 'student';
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  static const _roles = {
    'student': 'Student',
    'faculty': 'Faculty',
    'staff': 'Staff',
  };

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final app = context.read<AppState>();
    final err = await app.auth.signUp(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      dept: _dept.text,
      role: _role,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    AppUserRouter.routeAfterAuth(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Your details stay private.',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: Space.xs),
                Text(
                  'Admins only ever see a fun anonymous alias on your complaints — never your name.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: Space.lg),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: Space.md),
                TextFormField(
                  controller: _dept,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Department / branch (e.g. ISE)',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter your department'
                      : null,
                ),
                const SizedBox(height: Space.md),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: _roles.entries
                      .map((e) => DropdownMenuItem(
                          value: e.key, child: Text('I am a ${e.value}')))
                      .toList(),
                  onChanged: (v) => setState(() => _role = v ?? 'student'),
                ),
                const SizedBox(height: Space.md),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'College email',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email address'
                      : null,
                ),
                const SizedBox(height: Space.md),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Password (min. 6 characters)',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Use at least 6 characters'
                      : null,
                ),
                const SizedBox(height: Space.lg),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.md),
                    child: Text(_error!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error)),
                  ),
                FilledButton(
                  onPressed: _busy ? null : _signup,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
