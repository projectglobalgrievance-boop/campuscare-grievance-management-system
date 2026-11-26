import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/brand_logo.dart';
import '../admin/admin_shell.dart';
import '../student/student_shell.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final app = context.read<AppState>();
    final err = await app.auth.signIn(_email.text, _password.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    // Wait for the profile doc so we route to the right shell.
    AppUserRouter.routeAfterAuth(context);
  }

  Future<void> _forgot() async {
    final controller = TextEditingController(text: _email.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset password',
            style: Theme.of(ctx).textTheme.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'We\'ll email you a link to set a new password.'),
            const SizedBox(height: Space.md),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'College email',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Send link')),
        ],
      ),
    );
    if (email == null || email.isEmpty || !mounted) return;
    final err = await context.read<AppState>().auth.resetPassword(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ??
            'Reset link sent to $email — check your inbox (and spam).')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const GatLogo(
                          style: GatLogoStyle.stacked, height: 132)
                      .animate()
                      .scale(duration: Motion.normal, curve: Curves.easeOutBack),
                  const SizedBox(height: Space.md),
                  Text('Welcome back',
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: Space.xs),
                  Text('Sign in to ${AppConfig.appName}',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center),
                  const SizedBox(height: Space.xl),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
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
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Password must be at least 6 characters'
                        : null,
                    onFieldSubmitted: (_) => _login(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: _forgot, child: const Text('Forgot?')),
                  ),
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: Space.md),
                      padding: const EdgeInsets.all(Space.sm + 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Corners.sm),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 18, color: theme.colorScheme.error),
                          const SizedBox(width: Space.sm),
                          Expanded(
                            child: Text(_error!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error)),
                          ),
                        ],
                      ),
                    ).animate().shake(hz: 4, duration: Motion.normal),
                  FilledButton(
                    onPressed: _busy ? null : _login,
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5))
                        : const Text('Sign in'),
                  ),
                  const SizedBox(height: Space.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('New here? ', style: theme.textTheme.bodyMedium),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SignupScreen())),
                        child: const Text('Create an account'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Waits for the profile document, then replaces the stack with the right
/// shell. Shared by login and signup.
abstract final class AppUserRouter {
  static Future<void> routeAfterAuth(BuildContext context) async {
    final app = context.read<AppState>();
    // Profile stream may need a beat to deliver the doc.
    for (var i = 0; i < 40 && app.profile == null; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!context.mounted) return;
    final next = (app.profile?.isAdmin ?? false)
        ? const AdminShell()
        : const StudentShell();
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => next), (_) => false);
  }
}
