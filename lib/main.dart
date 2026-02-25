import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/budget_dashboard_screen.dart';
import 'screens/dashboard_showcase_screen.dart';
import 'screens/frontend_home_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SmartBudgetApp());
}

class SmartBudgetApp extends StatelessWidget {
  const SmartBudgetApp({
    super.key,
    this.splashDelay = const Duration(seconds: 4),
  });

  final Duration splashDelay;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightFinanceTheme,
      routes: <String, WidgetBuilder>{
        AuthScreen.routeName: (BuildContext context) => const AuthScreen(),
        BudgetDashboardScreen.routeName: (BuildContext context) =>
            const BudgetDashboardScreen(),
        FrontendHomeScreen.routeName: (BuildContext context) =>
            const FrontendHomeScreen(),
        DashboardShowcaseScreen.routeName: (BuildContext context) =>
            const DashboardShowcaseScreen(),
      },
      home: SplashScreen(delay: splashDelay),
    );
  }
}
