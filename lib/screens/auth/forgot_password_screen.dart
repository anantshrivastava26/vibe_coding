import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_slide_in.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail ?? '');
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthService>().sendPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_friendly(e))));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('invalid-email')) return 'That email address is invalid.';
    // Firebase may hide whether an account exists; treat it as a non-error path.
    if (s.contains('user-not-found')) return 'No account is registered with that email.';
    if (s.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a minute and try again.';
    }
    if (s.contains('network')) return 'Network error. Check your connection.';
    return 'Could not send the reset email. Please try again.';
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
                          child: _sent ? _confirmation() : _form(),
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

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_reset, size: 52, color: AppColors.red600),
          const SizedBox(height: 14),
          Text('Reset your password', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Enter the email you signed up with and we will send you a link to '
            'choose a new password.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send reset link', key: ValueKey('label')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 52, color: AppColors.severityLow),
        const SizedBox(height: 14),
        Text('Check your inbox', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'We sent a password reset link to ${_email.text.trim()}. Open it to set a '
          'new password, then sign in again.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to sign in'),
          ),
        ),
        TextButton(
          onPressed: _busy ? null : _submit,
          child: const Text("Didn't get it? Send again"),
        ),
      ],
    );
  }
}
