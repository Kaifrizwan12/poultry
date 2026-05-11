import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'modules/auth/controllers/auth_controller.dart';
import 'core/route_manager.dart';
import 'services/api_service.dart';
import 'services/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  registerSessionRefreshHandler(() => AuthController().refreshSession());
  final hasRefreshToken = LocalStorageService.refreshToken() != null;
  if ((LocalStorageService.token() == null ||
          LocalStorageService.isTokenExpired()) &&
      hasRefreshToken) {
    await AuthController().refreshSession();
  }

  final initialRoute = LocalStorageService.token() != null
      ? RouteManager.home
      : RouteManager.login;

  runApp(MyApp(initialRoute: initialRoute));
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
