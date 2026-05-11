import 'package:farm_mgt_auth/core/responsive.dart';
import 'package:flutter/material.dart';
import 'login_mobile.dart';
import 'login_tablet.dart';
import 'login_desktop.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
        mobile: const LoginMobile(),
        tablet: LoginTablet(),
        desktop: LoginDesktop());
  }
}
