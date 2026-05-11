import 'package:farm_mgt_auth/core/route_manager.dart';
import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../widgets/auth_shell.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class ResetView extends StatefulWidget {
  const ResetView({super.key});

  @override
  State<ResetView> createState() => _ResetViewState();
}

class _ResetViewState extends State<ResetView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _token = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  final AuthController _auth = AuthController();
  bool _submitted = false;
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () {
      if (mounted) {
        setState(() {});
      }
    };
    _auth.addListener(_listener);
  }

  @override
  void dispose() {
    _auth.removeListener(_listener);
    _token.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    final Map<String, dynamic> res = await _auth.resetPassword(
      _token.text.trim(),
      _password.text,
    );

    if (!mounted) return;
    if (res['ok'] == true || res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. You can sign in now.')),
      );
      Navigator.of(context).pushReplacementNamed(RouteManager.login);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(res['error']?.toString() ?? 'Password reset failed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final AuthViewport viewport = width >= 1100
        ? AuthViewport.desktop
        : width >= 700
            ? AuthViewport.tablet
            : AuthViewport.mobile;

    return AuthShell(
      viewport: viewport,
      eyebrow: 'Secure reset',
      heroTitle: 'Create a fresh password and get back to work.',
      panelTitle: 'Choose a new password',
      backLabel: 'Back to sign in',
      onBack: () =>
          Navigator.of(context).pushReplacementNamed(RouteManager.login),
      features: const <AuthFeature>[
        AuthFeature(
          icon: Icons.password_rounded,
          title: 'Consistent password rules',
          description:
              'Strength requirements only appear when they are actually relevant, not on first paint.',
        ),
      ],
      form: Form(
        key: _formKey,
        autovalidateMode: _submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          children: <Widget>[
            AuthTextField(
              controller: _token,
              label: 'Reset token',
              hintText: 'Paste your reset token',
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.key_rounded,
              validator: (String? value) =>
                  (value ?? '').trim().isEmpty ? 'Enter the reset token' : null,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _password,
              label: 'New password',
              hintText: 'Create a strong password',
              obscure: true,
              helperText:
                  'Use 8+ characters with an uppercase letter and a number.',
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.lock_outline_rounded,
              validator: (String? value) => _auth.validatePassword(value ?? ''),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _confirm,
              label: 'Confirm password',
              hintText: 'Retype your new password',
              obscure: true,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.verified_user_outlined,
              validator: (String? value) {
                if ((value ?? '').isEmpty) return 'Confirm your password';
                if (value != _password.text) return 'Passwords do not match';
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Update password',
              icon: Icons.check_circle_outline_rounded,
              onTap: _submit,
              loading: _auth.loading,
            ),
          ],
        ),
      ),
    );
  }
}
