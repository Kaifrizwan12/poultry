import 'package:farm_mgt_auth/core/route_manager.dart';
import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../widgets/auth_shell.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class ForgotRequestView extends StatefulWidget {
  const ForgotRequestView({super.key});

  @override
  State<ForgotRequestView> createState() => _ForgotRequestViewState();
}

class _ForgotRequestViewState extends State<ForgotRequestView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
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
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    final Map<String, dynamic> res =
        await _auth.forgotPassword(_email.text.trim());
    if (!mounted) return;

    if (res['token'] != null || res['ok'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['token'] != null
                ? 'Reset token issued for dev flow: ${res['token']}'
                : 'Reset instructions sent. Continue to set a new password.',
          ),
        ),
      );
      Navigator.of(context).pushNamed(RouteManager.reset);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(res['error']?.toString() ?? 'Failed to send reset request')),
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
      eyebrow: 'Password recovery',
      heroTitle: 'Recover access without the usual auth chaos.',
      panelTitle: 'Reset your password',
      backLabel: 'Back to sign in',
      onBack: () =>
          Navigator.of(context).pushReplacementNamed(RouteManager.login),
      features: const <AuthFeature>[
        AuthFeature(
          icon: Icons.mark_email_read_outlined,
          title: 'Clear recovery step',
          description:
              'Simple, single-purpose flow with no distracting fields or broken validation noise.',
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
              controller: _email,
              label: 'Account email',
              hintText: 'you@farmmgt.co',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.alternate_email_rounded,
              validator: (String? value) =>
                  _auth.validateEmail(value?.trim() ?? ''),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Send reset instructions',
              icon: Icons.send_rounded,
              onTap: _submit,
              loading: _auth.loading,
            ),
          ],
        ),
      ),
    );
  }
}
