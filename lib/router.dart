import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/api_providers.dart';
import 'screens/login_screen.dart';
import 'screens/reset_password_screen.dart' deferred as reset_password_screen;
import 'screens/mfa_screen.dart' deferred as mfa_screen;
import 'screens/home_screen.dart' deferred as home_screen;
import 'screens/users_admin_screen.dart' deferred as users_admin_screen;
import 'screens/doctor_panel_screen.dart' deferred as doctor_panel_screen;
import 'screens/patient_welcome_screen.dart' deferred as patient_welcome_screen;
import 'screens/patients_screen.dart' deferred as patients_screen;
import 'screens/create_patient_screen.dart' deferred as create_patient_screen;
import 'screens/patient_detail_screen.dart' deferred as patient_detail_screen;
import 'screens/consent_screen.dart' deferred as consent_screen;
import 'screens/new_session_screen.dart' deferred as new_session_screen;
import 'screens/test_selector_screen.dart' deferred as test_selector_screen;
import 'screens/profile_screen.dart' deferred as profile_screen;
import 'screens/test_placeholder_screen.dart'
    deferred as test_placeholder_screen;
import 'screens/results_screen.dart' deferred as results_screen;
import 'screens/history_screen.dart' deferred as history_screen;
import 'screens/report_preview_screen.dart' deferred as report_preview_screen;
import 'screens/reporte_cognitivo_screen.dart' deferred as reporte_cognitivo_screen;
import 'models/reporte_cognitivo_model.dart';
import 'games/visual_memory_game.dart' deferred as visual_memory_game;
import 'games/reaction_game.dart' deferred as reaction_game;
import 'games/fluency_game.dart' deferred as fluency_game;
import 'games/stroop_game.dart' deferred as stroop_game;
import 'games/common/game_flow.dart' deferred as game_flow;

typedef DeferredWidgetBuilder = Widget Function();

class DeferredRouteView extends StatefulWidget {
  const DeferredRouteView({
    super.key,
    required this.loadLibrary,
    required this.builder,
  });

  final Future<void> Function() loadLibrary;
  final DeferredWidgetBuilder builder;

  @override
  State<DeferredRouteView> createState() => _DeferredRouteViewState();
}

class _DeferredRouteViewState extends State<DeferredRouteView> {
  late final Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = widget.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return widget.builder();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loc = state.uri.path;

      // Keep the public landing/login route free of async provider startup.
      // This prevents local web storage/IndexedDB from being initialized during
      // Lighthouse's first paint audit.
      if (loc == '/' || loc == '/reset_password') {
        return null;
      }

      final api = ref.read(apiServiceProvider).value;
      final role = api?.currentRole;
      if (role == null) {
        return '/';
      }
      if (role == 'user') {
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
        const blocked = {'/create_patient', '/users_admin'};
        if (blocked.contains(loc)) {
          return '/home';
        }
      } else if (role == 'gestor') {
        const blocked = <String>{};
        if (blocked.contains(loc)) {
          return '/users_admin';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/reset_password',
        pageBuilder: (context, state) => _deferredPage(
          state,
          reset_password_screen.loadLibrary,
          () => reset_password_screen.ResetPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/mfa',
        builder: (context, state) => DeferredRouteView(
          loadLibrary: mfa_screen.loadLibrary,
          builder: () => mfa_screen.MfaScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _deferredPage(
          state,
          home_screen.loadLibrary,
          () => home_screen.HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/users_admin',
        builder: (context, state) => DeferredRouteView(
          loadLibrary: users_admin_screen.loadLibrary,
          builder: () => users_admin_screen.UsersAdminScreen(),
        ),
      ),
      GoRoute(
        path: '/doctor_panel',
        pageBuilder: (context, state) => _deferredPage(
          state,
          doctor_panel_screen.loadLibrary,
          () => doctor_panel_screen.DoctorPanelScreen(),
        ),
      ),
      GoRoute(
        path: '/patient_welcome',
        builder: (context, state) => DeferredRouteView(
          loadLibrary: patient_welcome_screen.loadLibrary,
          builder: () => patient_welcome_screen.PatientWelcomeScreen(),
        ),
      ),
      GoRoute(
        path: '/patients',
        builder: (context, state) => DeferredRouteView(
          loadLibrary: patients_screen.loadLibrary,
          builder: () => patients_screen.PatientsScreen(),
        ),
      ),
      GoRoute(
        path: '/create_patient',
        builder: (context, state) => DeferredRouteView(
          loadLibrary: create_patient_screen.loadLibrary,
          builder: () => create_patient_screen.CreatePatientScreen(),
        ),
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
          return DeferredRouteView(
            loadLibrary: patient_detail_screen.loadLibrary,
            builder: () => patient_detail_screen.PatientDetailScreen(
              patientName: patientName,
              patientId: patientId,
            ),
          );
        },
      ),
      GoRoute(
        path: '/consent',
        builder: (context, state) => DeferredRouteView(
          loadLibrary: consent_screen.loadLibrary,
          builder: () => consent_screen.ConsentScreen(),
        ),
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
          return DeferredRouteView(
            loadLibrary: new_session_screen.loadLibrary,
            builder: () =>
                new_session_screen.NewSessionScreen(patientId: patientId),
          );
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
          return DeferredRouteView(
            loadLibrary: test_selector_screen.loadLibrary,
            builder: () => test_selector_screen.TestSelectorScreen(
              initialSelection: initialSelection,
            ),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => DeferredRouteView(
          loadLibrary: profile_screen.loadLibrary,
          builder: () => profile_screen.ProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/test_placeholder',
        builder: (context, state) => DeferredRouteView(
          loadLibrary: test_placeholder_screen.loadLibrary,
          builder: () => test_placeholder_screen.TestPlaceholderScreen(),
        ),
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
          return _deferredPage(
            state,
            results_screen.loadLibrary,
            () => results_screen.ResultsScreen(
              data: data,
              dataFuture: dataFuture,
            ),
          );
        },
      ),
      GoRoute(
        path: '/history',
        pageBuilder: (context, state) => _deferredPage(
          state,
          history_screen.loadLibrary,
          () => history_screen.HistoryScreen(),
        ),
      ),
      GoRoute(
        path: '/report_preview',
        pageBuilder: (context, state) => _deferredPage(
          state,
          report_preview_screen.loadLibrary,
          () => report_preview_screen.ReportPreviewScreen(),
        ),
      ),
      GoRoute(
        path: '/reporte_cognitivo',
        pageBuilder: (context, state) {
          final extra = state.extra;
          final solicitud = extra is SolicitudReporteCognitivoModel
              ? extra
              : SolicitudReporteCognitivoModel.fromJson(
                  extra as Map<String, dynamic>,
                );
          return _deferredPage(
            state,
            reporte_cognitivo_screen.loadLibrary,
            () => reporte_cognitivo_screen.ReporteCognitivoScreen(
              solicitud: solicitud,
            ),
          );
        },
      ),
      GoRoute(
        path: '/game_memory',
        builder: (context, state) {
          final extra = state.extra;
          final flow = extra is Map ? extra['flow'] == true : false;
          final index = extra is Map ? extra['index'] as int? : null;
          final total = extra is Map ? extra['total'] as int? : null;
          final age = extra is Map ? extra['age'] as int? : null;
          return DeferredRouteView(
            loadLibrary: visual_memory_game.loadLibrary,
            builder: () => visual_memory_game.VisualMemoryGame(
              flowMode: flow,
              flowIndex: index,
              flowTotal: total,
              patientAge: age,
            ),
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
          return DeferredRouteView(
            loadLibrary: reaction_game.loadLibrary,
            builder: () => reaction_game.ReactionGame(
              flowMode: flow,
              flowIndex: index,
              flowTotal: total,
              patientAge: age,
            ),
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
          return DeferredRouteView(
            loadLibrary: fluency_game.loadLibrary,
            builder: () => fluency_game.FluencyGame(
              flowMode: flow,
              flowIndex: index,
              flowTotal: total,
              patientAge: age,
            ),
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
          return DeferredRouteView(
            loadLibrary: stroop_game.loadLibrary,
            builder: () => stroop_game.StroopGame(
              flowMode: flow,
              flowIndex: index,
              flowTotal: total,
              patientAge: age,
            ),
          );
        },
      ),
      GoRoute(
        path: '/game_flow',
        builder: (context, state) {
          final extra = state.extra;
          final routes = extra is Map ? extra['routes'] : null;
          final list = routes is List
              ? routes.cast<String>()
              : const <String>[];
          return DeferredRouteView(
            loadLibrary: game_flow.loadLibrary,
            builder: () => game_flow.GameFlow(gameRoutes: list),
          );
        },
      ),
    ],
  );
});

Page<void> _deferredPage(
  GoRouterState state,
  Future<void> Function() loadLibrary,
  DeferredWidgetBuilder builder,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: DeferredRouteView(loadLibrary: loadLibrary, builder: builder),
    transitionsBuilder: _fadeSlide,
    transitionDuration: const Duration(milliseconds: 260),
  );
}

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
