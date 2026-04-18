// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/services/firebase_auth_service.dart';
import 'core/services/firestore_service.dart';
import 'core/utils/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/savings_goal_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'logic/providers/auth_provider.dart';
import 'logic/providers/dashboard_provider.dart';
import 'logic/providers/savings_goal_provider.dart';
import 'logic/providers/transaction_provider.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await Firebase.initializeApp();

  runApp(const BudgetTrackerApp());
}

class BudgetTrackerApp extends StatelessWidget {
  const BudgetTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService      = FirebaseAuthService();
    final firestoreService = FirestoreService();
    final authRepo         = AuthRepository(authService);
    final txRepo           = TransactionRepository(firestoreService);
    final goalRepo         = SavingsGoalRepository(firestoreService); // ✅

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
        ChangeNotifierProvider(create: (_) => TransactionProvider(txRepo)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(firestoreService)),
        ChangeNotifierProvider(                                              // ✅
          create: (_) => SavingsGoalProvider(goalRepo),
        ),
      ],
      child: MaterialApp(
        title: 'BudgetWise',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.splash,
      ),
    );
  }
}