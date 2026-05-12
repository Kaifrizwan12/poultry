import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'modules/auth/controllers/auth_controller.dart';
import 'core/route_manager.dart';
import 'services/api_service.dart';
import 'services/local_storage_service.dart';
import 'services/offline_cache_service.dart';
import 'services/offline_queue_service.dart';
import 'services/offline_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise SharedPreferences once; share the instance across all services.
  await LocalStorageService.init();
  final prefs = LocalStorageService.prefs;
  OfflineCacheService.init(prefs);
  OfflineQueueService.init(prefs);

  registerSessionRefreshHandler(() => AuthController().refreshSession());

  final initialRoute = await _resolveInitialRoute();

  if (initialRoute == RouteManager.root) {
    // Start the background sync service so any pending offline ops are
    // flushed as soon as connectivity is available.
    OfflineSyncService.instance.start();
  }

  runApp(MyApp(initialRoute: initialRoute));
}

/// Determines the starting route without blocking the UI for longer than
/// necessary. The priority order mirrors the [AuthGuard] decision table:
///   1. Valid non-expired token            → home
///   2. Expired token + refresh succeeds   → home
///   3. Expired/missing token + offline OK → home (offline mode)
///   4. Nothing valid                      → login
Future<String> _resolveInitialRoute() async {
  final hasToken   = LocalStorageService.token() != null;
  final expired    = LocalStorageService.isTokenExpired();
  final hasRefresh = LocalStorageService.refreshToken() != null;
  final canOffline = LocalStorageService.offlineAllowed() &&
      LocalStorageService.cachedUser() != null;

  debugPrint('[STARTUP] hasToken=$hasToken  expired=$expired'
      '  hasRefresh=$hasRefresh  offlineAllowed=$canOffline');

  if (hasToken && !expired) {
    debugPrint('[STARTUP] → valid token  route=/ (online)');
    return RouteManager.root;
  }

  if (hasRefresh) {
    debugPrint('[STARTUP] → attempting token refresh…');
    final ok = await AuthController().refreshSession();
    if (ok) {
      debugPrint('[STARTUP] → refresh OK  route=/ (online)');
      return RouteManager.root;
    }
    debugPrint('[STARTUP] → refresh failed – checking offline fallback');
  }

  if (canOffline) {
    debugPrint('[STARTUP] → offlineAllowed=true  route=/ (offline mode)');
    return RouteManager.root;
  }

  debugPrint('[STARTUP] → no valid session  route=login');
  return RouteManager.login;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.initialRoute});
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farm Management SaaS',
      theme: AppTheme.light(),
      onGenerateRoute: RouteManager.generateRoute,
      initialRoute: initialRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
