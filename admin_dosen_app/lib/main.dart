import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/auth_provider.dart';
import 'features/admin/dashboard_provider.dart';
import 'features/admin/dashboard_screen.dart';

void main() {
  runApp(const PortalAkademikWeb());
}

class PortalAkademikWeb extends StatelessWidget {
  const PortalAkademikWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider(apiClient)),
        ChangeNotifierProvider<DashboardProvider>(create: (_) => DashboardProvider(apiClient)),
      ],
      child: MaterialApp(
        title: 'Portal Akademik - Dosen & Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}
