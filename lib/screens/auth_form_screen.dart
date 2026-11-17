import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import '../services/api_client.dart';
import '../widgets/auth_field.dart';
import 'browse_screen.dart';

class AuthFormScreen extends StatefulWidget {
  const AuthFormScreen({
    super.key,
    required this.isSignUp,
    this.forgotPassword = false,
  });

  final bool isSignUp;
  final bool forgotPassword;

  @override
  State<AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends State<AuthFormScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetTokenController = TextEditingController();
  bool _isSubmitting = false;
  bool _resetLinkRequested = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _resetTokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final email = _emailController.text.trim();
    if (email.isEmpty ||
        (!widget.forgotPassword && _passwordController.text.isEmpty) ||
        (_resetLinkRequested &&
            (_resetTokenController.text.trim().isEmpty ||
                _passwordController.text.isEmpty)) ||
        (widget.isSignUp && _nameController.text.trim().isEmpty)) {
      _showMessage('Please fill in all required fields.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (widget.forgotPassword) {
        if (_resetLinkRequested) {
          await ApiClient.instance.resetPassword(
            token: _resetTokenController.text.trim(),
            password: _passwordController.text,
          );
          if (!mounted) return;
          _showMessage('Password updated. You can now sign in.');
          Navigator.pop(context);
        } else {
          await ApiClient.instance.requestPasswordReset(email);
          if (!mounted) return;
          setState(() => _resetLinkRequested = true);
          _showMessage(
            'If registered, check your email and paste the reset token here.',
          );
        }
      } else {
        if (widget.isSignUp) {
          await ApiClient.instance.register(
            name: _nameController.text.trim(),
            email: email,
            password: _passwordController.text,
          );
        } else {
          await ApiClient.instance.login(
            email: email,
            password: _passwordController.text,
          );
        }
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const BrowseScreen()),
          (_) => false,
        );
      }
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } on http.ClientException {
      if (mounted) {
        _showMessage(
          'Could not connect to PlotPost. Check the API server URL.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.forgotPassword
        ? 'Reset password'
        : (widget.isSignUp ? 'Create account' : 'Welcome back');
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 92,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Image.asset(
            'lib/theme/logo.png',
            height: 54,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.forgotPassword
                  ? 'Enter your email to reset your password.'
                  : (widget.isSignUp
                        ? 'Join the PlotPost community.'
                        : 'Log in to your PlotPost account.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),
            if (widget.isSignUp) ...[
              AuthField(
                controller: _nameController,
                hint: 'Full name',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 12),
            ],
            AuthField(
              controller: _emailController,
              hint: 'Email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            if (widget.forgotPassword && _resetLinkRequested) ...[
              const SizedBox(height: 12),
              AuthField(
                controller: _resetTokenController,
                hint: 'Reset token from email link',
                icon: Icons.key_outlined,
              ),
              const SizedBox(height: 12),
              AuthField(
                controller: _passwordController,
                hint: 'New password',
                icon: Icons.lock_outline_rounded,
                obscure: true,
              ),
            ] else if (!widget.forgotPassword) ...[
              const SizedBox(height: 12),
              AuthField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                obscure: true,
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              height: 49,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF174B3A)
                      : Theme.of(context).colorScheme.primary,
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.forgotPassword
                            ? (_resetLinkRequested
                                  ? 'Reset password'
                                  : 'Send reset link')
                            : (widget.isSignUp ? 'Create Account' : 'Log In'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
