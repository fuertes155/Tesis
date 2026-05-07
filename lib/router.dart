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
import 'screens/doctor_panel_screen.dart';
import 'games/visual_memory_game.dart';
import 'games/reaction_game.dart';
import 'games/fluency_game.dart';
import 'games/stroop_game.dart';
import 'games/common/game_flow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/api_providers.dart';
import 'screens/patient_welcome_screen.dart';
import 'screens/users_admin_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/mfa_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final api = ref.read(apiServiceProvider).value;
      final role = api?.currentRole;
      final loc = state.uri.path;
      if (role == null && loc != '/' && loc != '/reset_password') {
        return '/';
      }
      if (role == 'user') {
        // Rutas restringidas para Paciente
        const blocked = {
          '/home',
          '/patients',
          '/create_patient',
          '/patient_detail',
          '/new_session',
          '/history',
          '/report_preview',
        };
        if (blocked.contains(loc)) {
          return '/patient_welcome';
        }
      } else if (role == 'doctor') {
        // Rutas restringidas para Doctor: gestión de pacientes/usuarios
        const blocked = {'/create_patient', '/users_admin'};
        if (blocked.contains(loc)) {
          return '/home';
        }
      } else if (role == 'gestor') {
        // Rutas restringidas para Gestor
        const blocked = <String>{};
        if (blocked.contains(loc)) {
          return '/users_admin';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/mfa', builder: (context, state) => const MfaScreen()),
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
        path: '/users_admin',
        builder: (context, state) => const UsersAdminScreen(),
      ),
      GoRoute(
        path: '/doctor_panel',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DoctorPanelScreen(),
          transitionsBuilder: _fadeSlide,
          transitionDuration: const Duration(milliseconds: 260),
        ),
      ),
      GoRoute(
        path: '/patient_welcome',
        builder: (context, state) => const PatientWelcomeScreen(),
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
          return PatientDetailScreen(
            patientName: patientName,
            patientId: patientId,
          );
        },
      ),
      GoRoute(
        path: '/consent',
        builder: (context, state) => const ConsentScreen(),
      ),
      GoRoute(
        path: '/new_session',
        builder: (context, state) {
          final extra = state.extra;
          int? patientId;
          if (extra is int) {
            patientId = extra;
          } else if (extra is Map<String, dynamic>) {
            final v = extra['patientId'];
            if (v is int) patientId = v;
            if (v is String) patientId = int.tryParse(v);
          }
          return NewSessionScreen(patientId: patientId);
        },
      ),
      GoRoute(
        path: '/test_selector',
        builder: (context, state) {
          final extra = state.extra;
          List<String>? initialSelection;
          if (extra is Map<String, dynamic>) {
            final sel = extra['initialSelection'];
            if (sel is List) {
              initialSelection = sel.cast<String>();
            }
          }
          return TestSelectorScreen(initialSelection: initialSelection);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
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
        builder: (context, state) {
          final extra = state.extra;
          final flow = extra is Map ? extra['flow'] == true : false;
          final index = extra is Map ? extra['index'] as int? : null;
          final total = extra is Map ? extra['total'] as int? : null;
          final age = extra is Map ? extra['age'] as int? : null;
          return VisualMemoryGame(
            flowMode: flow,
            flowIndex: index,
            flowTotal: total,
            patientAge: age,
          );
        },
      ),
      GoRoute(
        path: '/game_reaction',
        builder: (context, state) {
          final extra = state.extra;
          final flow = extra is Map ? extra['flow'] == true : false;
          final index = extra is Map ? extra['index'] as int? : null;
          final total = extra is Map ? extra['total'] as int? : null;
          final age = extra is Map ? extra['age'] as int? : null;
          return ReactionGame(
            flowMode: flow,
            flowIndex: index,
            flowTotal: total,
            patientAge: age,
          );
        },
      ),
      GoRoute(
        path: '/game_fluency',
        builder: (context, state) {
          final extra = state.extra;
          final flow = extra is Map ? extra['flow'] == true : false;
          final index = extra is Map ? extra['index'] as int? : null;
          final total = extra is Map ? extra['total'] as int? : null;
          final age = extra is Map ? extra['age'] as int? : null;
          return FluencyGame(
            flowMode: flow,
            flowIndex: index,
            flowTotal: total,
            patientAge: age,
          );
        },
      ),
      GoRoute(
        path: '/game_stroop',
        builder: (context, state) {
          final extra = state.extra;
          final flow = extra is Map ? extra['flow'] == true : false;
          final index = extra is Map ? extra['index'] as int? : null;
          final total = extra is Map ? extra['total'] as int? : null;
          final age = extra is Map ? extra['age'] as int? : null;
          return StroopGame(
            flowMode: flow,
            flowIndex: index,
            flowTotal: total,
            patientAge: age,
          );
        },
      ),
      GoRoute(
        path: '/game_flow',
        builder: (context, state) {
          final extra = state.extra;
          final routes = extra is Map ? extra['routes'] : null;
          final list = routes is List ? routes.cast<String>() : const <String>[];
          return GameFlow(gameRoutes: list);
        },
      ),
    ],
  );
});

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
