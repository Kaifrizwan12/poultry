import 'package:flutter/material.dart';

import '../modules/auth/controllers/auth_controller.dart';
import '../services/local_storage_service.dart';
import 'route_manager.dart';

class AuthGuard extends StatefulWidget {
  const AuthGuard({super.key, required this.child});

  final Widget child;

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _check();
    });
  }

  Future<void> _check() async {
    if (LocalStorageService.token() == null) {
      _redirect();
      return;
    }

    if (LocalStorageService.isTokenExpired()) {
      final ok = await AuthController().refreshSession();
      if (!ok) {
        _redirect();
        return;
      }
    }

    if (mounted) {
      setState(() => _checked = true);
    }
  }

  void _redirect() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(RouteManager.login);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checked) {
      return widget.child;
    }

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
