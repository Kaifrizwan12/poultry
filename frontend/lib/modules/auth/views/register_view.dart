import 'package:farm_mgt_auth/core/responsive.dart';
import 'package:flutter/material.dart';
import 'register_mobile.dart';
import 'register_tablet.dart';
import 'register_desktop.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
        mobile: RegisterMobile(),
        tablet: RegisterTablet(),
        desktop: RegisterDesktop());
  }
}
