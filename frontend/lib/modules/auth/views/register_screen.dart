import 'package:farm_mgt_auth/core/route_manager.dart';
import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../widgets/auth_shell.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/saas_dropdown.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.viewport});

  final AuthViewport viewport;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final AuthController _auth = AuthController();
  String? _farmType;
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    final valid = _formKey.currentState!.validate();
    if (!valid || _farmType == null) {
      if (_farmType == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Choose the farm profile that matches your operation.')),
        );
      }
      return;
    }

    final ok = await _auth.register(<String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'farmType': _farmType,
    });

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed(RouteManager.home);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Account setup failed. Please review the details and try again.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      viewport: widget.viewport,
      eyebrow: 'Onboard your operation',
      heroTitle: 'Set up a sharper farm workspace from day one! Enjoy.',
      panelTitle: 'Create account',
      backLabel: 'Back to sign in',
      onBack: () =>
          Navigator.of(context).pushReplacementNamed(RouteManager.login),
      features: const <AuthFeature>[
        AuthFeature(
          icon: Icons.grid_view_rounded,
          title: 'Clean multi-device onboarding',
          description:
              'The same flow works on mobile, tablet, and desktop without those broken tiny boxes.',
        ),
        AuthFeature(
          icon: Icons.track_changes_outlined,
          title: 'Structured farm setup',
          description:
              'Map your operation type first so reporting and task flows fit the business immediately.',
        ),
        AuthFeature(
          icon: Icons.auto_graph_rounded,
          title: 'Ready for scale',
          description:
              'The visual system stays usable as you add teams, locations, and daily operational data.',
        ),
      ],
      form: Form(
        key: _formKey,
        autovalidateMode: _submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AuthTextField(
              controller: _nameController,
              label: 'Full name',
              hintText: 'Sarah Johnson',
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.person_outline_rounded,
              validator: (String? value) =>
                  _auth.validateName(value?.trim() ?? ''),
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _emailController,
              label: 'Work email',
              hintText: 'you@farmmgt.co',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.alternate_email_rounded,
              validator: (String? value) =>
                  _auth.validateEmail(value?.trim() ?? ''),
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _passwordController,
              label: 'Password',
              hintText: 'At least 8 characters',
              obscure: true,
              helperText:
                  'Use 8+ characters with an uppercase letter and a number.',
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.lock_outline_rounded,
              validator: (String? value) => _auth.validatePassword(value ?? ''),
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _confirmController,
              label: 'Confirm password',
              hintText: 'Retype your password',
              obscure: true,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.verified_user_outlined,
              validator: (String? value) {
                if ((value ?? '').isEmpty) return 'Confirm your password';
                if (value != _passwordController.text)
                  return 'Passwords do not match';
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            SaasDropdown(
              value: _farmType,
              onChanged: (String? value) => setState(() => _farmType = value),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Create FarmMGT workspace',
              icon: Icons.arrow_forward_rounded,
              onTap: _submit,
              loading: _auth.loading,
            ),
            const SizedBox(height: 12),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    'Already have an account?',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushReplacementNamed(RouteManager.login),
                    child: const Text('Sign in instead'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
