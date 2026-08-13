import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_slide_in.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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
      await context.read<AuthService>().register(_email.text.trim(), _password.text);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_friendly(e))));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('email-already-in-use')) return 'That email is already registered.';
    if (s.contains('weak-password')) return 'Password is too weak.';
    if (s.contains('invalid-email')) return 'That email address is invalid.';
    return 'Registration failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: FadeSlideIn(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Create account',
                                    style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 6),
                                const Text(
                                  'Get alerted about disasters near you',
                                  style: TextStyle(fontSize: 13, color: Colors.black54),
                                ),
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
                                const SizedBox(height: 24),
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
                                          : const Text('Create Account', key: ValueKey('label')),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
