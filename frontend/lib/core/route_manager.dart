import 'package:flutter/material.dart';

import 'auth_guard.dart';
import '../modules/auth/views/forgot_request_view.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/views/register_view.dart';
import '../modules/auth/views/reset_view.dart';
import '../modules/shell/main_shell.dart';

class RouteManager {
  static const String root = '/';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String settingsCategory = '/settings/category';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgot = '/forgot';
  static const String reset = '/reset';

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case root:
      case home:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(
            child: MainShell(initialModuleIndex: 0),
          ),
        );
      case RouteManager.settings:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(
            child: MainShell(initialModuleIndex: 1),
          ),
        );
      case RouteManager.settingsCategory:
        final categoryId = settings.arguments is String
            ? settings.arguments as String
            : null;
        return MaterialPageRoute(
          builder: (_) => AuthGuard(
            child: MainShell(
              initialModuleIndex: 1,
              initialSettingsCategoryId: categoryId,
            ),
          ),
        );
      case login:
        return MaterialPageRoute(builder: (_) => const LoginView());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterView());
      case forgot:
        return MaterialPageRoute(builder: (_) => const ForgotRequestView());
      case reset:
        return MaterialPageRoute(builder: (_) => const ResetView());
      default:
        return MaterialPageRoute(builder: (_) => const LoginView());
    }
  }
}
