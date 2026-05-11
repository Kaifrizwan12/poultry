import 'package:farm_mgt_auth/core/route_manager.dart';
import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../widgets/auth_shell.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.viewport});

  final AuthViewport viewport;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthController _auth = AuthController();
  bool _rememberMe = true;
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    final ok = await _auth.login(
      _emailController.text.trim(),
      _passwordController.text,
      remember: _rememberMe,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed(RouteManager.home);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Could not sign you in. Check your credentials and try again.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      viewport: widget.viewport,
      eyebrow: 'Farm operations cloud',
      heroTitle: 'Welcome back to the farm control room.',
      panelTitle: 'Sign in',
      features: const <AuthFeature>[
        AuthFeature(
          icon: Icons.analytics_outlined,
          title: 'Live performance snapshots',
          description:
              'Follow production, feed, labor, and field activity in one decision-ready view.',
        ),
        AuthFeature(
          icon: Icons.eco_outlined,
          title: 'Season-aware planning',
          description:
              'Keep planting, irrigation, and treatment schedules aligned with real farm rhythms.',
        ),
        AuthFeature(
          icon: Icons.verified_user_outlined,
          title: 'Secure team access',
          description:
              'Give managers and operators the right level of visibility without extra friction.',
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
              controller: _emailController,
              label: 'Work email',
              hintText: 'you@farmmgt.co',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.alternate_email_rounded,
              validator: (String? value) =>
                  _auth.validateEmail(value?.trim() ?? ''),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _passwordController,
              label: 'Password',
              hintText: 'Enter your password',
              obscure: true,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline_rounded,
              validator: _auth.validateLoginPassword,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: CheckboxListTile(
                    value: _rememberMe,
                    onChanged: (bool? value) {
                      setState(() => _rememberMe = value ?? false);
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Keep me signed in'),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(RouteManager.forgot),
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Sign in to dashboard',
              icon: Icons.arrow_forward_rounded,
              onTap: _submit,
              loading: _auth.loading,
            ),
            const SizedBox(height: 18),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    'New to FarmMGT?',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(RouteManager.register),
                    child: const Text('Create your account'),
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
