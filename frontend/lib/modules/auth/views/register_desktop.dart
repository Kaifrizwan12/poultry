import 'package:flutter/material.dart';

import '../widgets/auth_shell.dart';
import 'register_screen.dart';

class RegisterDesktop extends StatelessWidget {
  const RegisterDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return const RegisterScreen(viewport: AuthViewport.desktop);
  }
}
