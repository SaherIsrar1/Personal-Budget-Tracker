import 'package:flutter/material.dart';
import '../logic/providers/auth_provider.dart';
import '../view/screens/splash_screen.dart';
import '../view/screens/signin_screen.dart';
import '../view/screens/signup_screen.dart';
import '../view/screens/onboarding_welcome_screen.dart';
import '../view/screens/home_dashboard_screen.dart';
import '../view/screens/settings_profile_screen.dart';

class AppRouter {
  static const String splash     = '/';
  static const String signIn     = '/sign-in';
  static const String signUp     = '/sign-up';
  static const String onboarding = '/onboarding';
  static const String dashboard  = '/dashboard';
  static const String settings   = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    final name = routeSettings.name;
    if (name == splash)     return _fade(const SplashScreen());
    if (name == signIn)     return _slide(const SignInScreen());
    if (name == signUp)     return _slide(const SignUpScreen());
    if (name == onboarding) return _fade(const OnboardingWelcomeScreen());
    if (name == dashboard)  return _fade(const HomeDashboardScreen());
    if (name == settings)   return _slide(const SettingsProfileScreen());
    return _fade(const SplashScreen());
  }

  static String initialRoute(AuthStatus status) {
    if (status == AuthStatus.authenticated) return dashboard;
    if (status == AuthStatus.unauthenticated || status == AuthStatus.error) return signIn;
    return splash;
  }

  static PageRoute _fade(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      );

  static PageRoute _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 380),
      );
}
