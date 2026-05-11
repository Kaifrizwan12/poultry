import 'package:flutter/material.dart';

import '../widgets/auth_shell.dart';
import 'login_screen.dart';

class LoginTablet extends StatelessWidget {
  const LoginTablet({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(viewport: AuthViewport.tablet);
  }
}
