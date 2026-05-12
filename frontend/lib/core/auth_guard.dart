import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../modules/auth/controllers/auth_controller.dart';
import '../services/local_storage_service.dart';
import '../services/offline_sync_service.dart';
import 'route_manager.dart';

/// Guards protected routes.
///
/// Decision table:
/// 1. Valid non-expired token             → pass through immediately.
/// 2. Expired token, refresh succeeds     → pass through.
/// 3. Expired token, no network, but device has a prior offline-allowed session
///    with a cached user                  → pass through in offline mode.
/// 4. No token at all, offline-allowed    → pass through in offline mode.
/// 5. Anything else                       → redirect to login.
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final hasToken   = LocalStorageService.token() != null;
    final expired    = LocalStorageService.isTokenExpired();
    final hasUser    = LocalStorageService.cachedUser() != null;
    final canOffline = LocalStorageService.offlineAllowed() && hasUser;

    if (kDebugMode) {
      debugPrint('[AUTH_GUARD] check  hasToken=$hasToken  expired=$expired'
          '  hasUser=$hasUser  offlineAllowed=$canOffline');
    }

    if (hasToken && !expired) {
      if (kDebugMode) debugPrint('[AUTH_GUARD] → valid token – ALLOW');
      _allow();
      return;
    }

    if (expired || !hasToken) {
      if (kDebugMode) debugPrint('[AUTH_GUARD] token missing/expired – trying refresh…');
      final ok = await AuthController().refreshSession();
      if (ok) {
        if (kDebugMode) debugPrint('[AUTH_GUARD] → refresh OK – ALLOW (online)');
        _allow();
        return;
      }
      if (canOffline) {
        if (kDebugMode) {
          debugPrint('[AUTH_GUARD] → refresh failed but offlineAllowed=true'
              ' – ALLOW (offline mode)');
        }
        _allow();
        return;
      }
      if (kDebugMode) debugPrint('[AUTH_GUARD] → no session – REDIRECT to login');
      _redirect();
      return;
    }

    _allow();
  }

  void _allow() {
    if (!mounted) return;
    // Ensure the sync service is running (may have been stopped or never started).
    OfflineSyncService.instance.start();
    setState(() => _checked = true);
  }

  void _redirect() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(RouteManager.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checked) return widget.child;
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
