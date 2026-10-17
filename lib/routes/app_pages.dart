import 'package:flutter/material.dart';
import 'package:flutter_srvei2/screens/auth/register.dart';
import 'package:flutter_srvei2/screens/dashboard/dashboard.dart';
import 'package:flutter_srvei2/screens/dashboard/edit_profile.dart';
import 'package:flutter_srvei2/screens/dashboard/profile.dart';
import 'package:flutter_srvei2/screens/survey/survey.dart';
import 'package:flutter_srvei2/screens/survey/formsurvey.dart';
// IMPORT HALAMAN DETAIL SURVEY DI SINI:
import 'package:flutter_srvei2/screens/survey/SurveyDetailPage.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/login_page.dart';
import '../screens/splash/splash_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (BuildContext context, GoRouterState state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (BuildContext context, GoRouterState state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (BuildContext context, GoRouterState state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (BuildContext context, GoRouterState state) => DashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.survey,
        builder: (BuildContext context, GoRouterState state) => const SurveyPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (BuildContext context, GoRouterState state) => ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.edit,
        builder: (BuildContext context, GoRouterState state) {
          final userData = (state.extra as Map<String, dynamic>?) ?? {};
          return EditProfilePage(userData: userData);
        },
      ),
      GoRoute(
        path: AppRoutes.detail_survey,
        builder: (BuildContext context, GoRouterState state) {
          final surveyId = state.extra as int? ?? 0;
          return SurveyScreen(surveyId: surveyId);
        },
      ),
      GoRoute(
        path: AppRoutes.add_survey, // Pastikan variabel nama route ini ada di AppRoutes (misal: '/add-survey')
        builder: (BuildContext context, GoRouterState state) {
          final survey = state.extra as Map<String, dynamic>?;
          return Formsurvey(
            survey: survey,
          );
        }
      ),
      // Di dalam penyiapan GoRouter Anda pada app_pages.dart:
      
    ],
  );
}