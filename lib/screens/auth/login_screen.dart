import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/page_transitions.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

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

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthService>().login(_email.text.trim(), _password.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_friendly(e))));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('invalid-credential') || s.contains('wrong-password') || s.contains('user-not-found')) {
      return 'Incorrect email or password.';
    }
    if (s.contains('network')) return 'Network error. Check your connection.';
    return 'Sign in failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FadeSlideIn(
                    child: Column(
                      children: [
                        Icon(Icons.crisis_alert, size: 68, color: Colors.white),
                        SizedBox(height: 12),
                        Text(
                          'LifeLoop',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Real-time disaster alerts for your area',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  FadeSlideIn(
                    index: 1,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Welcome back', style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                                validator: (v) =>
                                    (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _password,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                validator: (v) =>
                                    (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => Navigator.of(context).push(
                                            smoothRoute(ForgotPasswordScreen(
                                              initialEmail: _email.text.trim(),
                                            )),
                                          ),
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _busy ? null : _submit,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    child: _busy
                                        ? const SizedBox(
                                            key: ValueKey('busy'),
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Sign In', key: ValueKey('label')),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => Navigator.of(context)
                                        .push(smoothRoute(const RegisterScreen())),
                                child: const Text("Don't have an account? Create one"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
