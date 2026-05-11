import 'package:flutter/material.dart';

import '../widgets/auth_shell.dart';
import 'login_screen.dart';

class LoginDesktop extends StatelessWidget {
  const LoginDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(viewport: AuthViewport.desktop);
  }
}
