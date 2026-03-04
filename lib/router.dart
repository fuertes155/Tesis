import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/patients_screen.dart';
import 'screens/create_patient_screen.dart';
import 'screens/patient_detail_screen.dart';
import 'screens/consent_screen.dart';
import 'screens/new_session_screen.dart';
import 'screens/test_selector_screen.dart';
import 'screens/test_placeholder_screen.dart';
import 'screens/results_screen.dart';
import 'screens/history_screen.dart';
import 'screens/report_preview_screen.dart';
import 'screens/reset_password_screen.dart';
import 'games/visual_memory_game.dart';
import 'games/reaction_game.dart';
import 'games/fluency_game.dart';
import 'games/stroop_game.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HomeScreen(),
        transitionsBuilder: _fadeSlide,
        transitionDuration: const Duration(milliseconds: 260),
      ),
    ),
    GoRoute(
      path: '/patients',
      builder: (context, state) => const PatientsScreen(),
    ),
    GoRoute(
      path: '/create_patient',
      builder: (context, state) => const CreatePatientScreen(),
    ),
    GoRoute(
      path: '/patient_detail',
      builder: (context, state) {
        String patientName = 'Paciente';
        int? patientId;
        final extra = state.extra;
        if (extra is String) {
          patientName = extra;
        } else if (extra is Map<String, dynamic>) {
          patientName = extra['name'] as String? ?? patientName;
          final idVal = extra['id'];
          if (idVal is int) patientId = idVal;
          if (idVal is String) patientId = int.tryParse(idVal);
        }
        return PatientDetailScreen(patientName: patientName, patientId: patientId);
      },
    ),
    GoRoute(
      path: '/consent',
      builder: (context, state) => const ConsentScreen(),
    ),
    GoRoute(
      path: '/new_session',
      builder: (context, state) => const NewSessionScreen(),
    ),
    GoRoute(
      path: '/test_selector',
      builder: (context, state) => const TestSelectorScreen(),
    ),
    GoRoute(
      path: '/test_placeholder',
      builder: (context, state) => const TestPlaceholderScreen(),
    ),
    GoRoute(
      path: '/results',
      pageBuilder: (context, state) {
        final extra = state.extra;
        Map<String, dynamic>? data;
        Future<Map<String, dynamic>>? dataFuture;
        if (extra is Map<String, dynamic>) {
          if (extra['dataFuture'] is Future<Map<String, dynamic>>) {
            dataFuture = extra['dataFuture'] as Future<Map<String, dynamic>>;
          } else {
            data = extra;
          }
        }
        return CustomTransitionPage(
          key: state.pageKey,
          child: ResultsScreen(data: data, dataFuture: dataFuture),
          transitionsBuilder: _fadeSlide,
          transitionDuration: const Duration(milliseconds: 280),
        );
      },
    ),
    GoRoute(
      path: '/history',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HistoryScreen(),
        transitionsBuilder: _fadeSlide,
        transitionDuration: const Duration(milliseconds: 260),
      ),
    ),
    GoRoute(
      path: '/report_preview',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ReportPreviewScreen(),
        transitionsBuilder: _fadeSlide,
        transitionDuration: const Duration(milliseconds: 260),
      ),
    ),
    GoRoute(
      path: '/reset_password',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ResetPasswordScreen(),
        transitionsBuilder: _fadeSlide,
        transitionDuration: const Duration(milliseconds: 260),
      ),
    ),
    GoRoute(
      path: '/game_memory',
      builder: (context, state) => const VisualMemoryGame(),
    ),
    GoRoute(
      path: '/game_reaction',
      builder: (context, state) => const ReactionGame(),
    ),
    GoRoute(
      path: '/game_fluency',
      builder: (context, state) => const FluencyGame(),
    ),
    GoRoute(
      path: '/game_stroop',
      builder: (context, state) => const StroopGame(),
    ),
  ],
);

Widget _fadeSlide(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondary,
  Widget child,
) {
  final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
  final slide = Tween<Offset>(
    begin: const Offset(0, 0.05),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
  return FadeTransition(
    opacity: fade,
    child: SlideTransition(position: slide, child: child),
  );
}
