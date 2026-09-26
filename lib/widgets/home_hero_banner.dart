import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../providers/data_providers.dart';

/// Bienvenida del panel: saludo, resumen del día y acciones principales.
class HomeHeroBanner extends ConsumerWidget {
  const HomeHeroBanner({
    super.key,
    required this.loading,
    required this.sessionsToday,
    required this.sessionsPending,
    required this.role,
    required this.fallbackName,
    required this.onNewSession,
    required this.onPatients,
    required this.onResults,
  });

  final bool loading;
  final int sessionsToday;
  final int sessionsPending;
  final String? role;
  final String fallbackName;
  final VoidCallback onNewSession;
  final VoidCallback onPatients;
  final VoidCallback onResults;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final usuario = ref.watch(currentUserProvider).valueOrNull;
    final nombreCompleto = (usuario?.fullName?.trim().isNotEmpty ?? false)
        ? usuario!.fullName!.trim()
        : (usuario?.username ?? fallbackName);
    final nombre = nombreCompleto.split(RegExp(r'\s+')).first;

    final ahora = DateTime.now();
    final saludo = ahora.hour < 12
        ? 'Buenos días'
        : ahora.hour < 19
            ? 'Buenas tardes'
            : 'Buenas noches';
    final fecha = DateFormat("EEEE, d 'de' MMMM", 'es').format(ahora);
    final fechaCapitalizada = fecha[0].toUpperCase() + fecha.substring(1);

    final esPaciente = role == 'user';
    final resumen = esPaciente
        ? 'Aquí puedes consultar tus resultados y reportes.'
        : loading
            ? 'Cargando tu resumen del día…'
            : 'Hoy hay $sessionsToday ${sessionsToday == 1 ? 'sesión registrada' : 'sesiones registradas'}'
                ' y $sessionsPending ${sessionsPending == 1 ? 'pendiente' : 'pendientes'} por completar.';

    final estiloBotonPrincipal = FilledButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primaryDeep,
    );
    final estiloBotonSecundario = OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth > 720;

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: context.glass.headerGradient,
            borderRadius: context.radii.radiusXl,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 32,
                spreadRadius: -12,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Formas decorativas
              Positioned(
                right: -60,
                top: -80,
                child: _Circulo(diametro: 260, alpha: 0.08),
              ),
              Positioned(
                right: 120,
                bottom: -90,
                child: _Circulo(diametro: 180, alpha: 0.06),
              ),
              if (ancho)
                Positioned(
                  right: 40,
                  top: 0,
                  bottom: 0,
                  child: Icon(
                    Icons.psychology_alt_rounded,
                    size: 150,
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(ancho ? 32 : 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 13, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            fechaCapitalizada,
                            style: theme.textTheme.labelMedium?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$saludo, $nombre 👋',
                      style: (ancho ? theme.textTheme.headlineMedium : theme.textTheme.headlineSmall)
                          ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Text(
                        resumen,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: esPaciente
                          ? [
                              FilledButton.icon(
                                style: estiloBotonPrincipal,
                                onPressed: onResults,
                                icon: const Icon(Icons.analytics_rounded, size: 18),
                                label: const Text('Ver mis resultados'),
                              ),
                            ]
                          : [
                              FilledButton.icon(
                                style: estiloBotonPrincipal,
                                onPressed: onNewSession,
                                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                                label: const Text('Nueva sesión'),
                              ),
                              OutlinedButton.icon(
                                style: estiloBotonSecundario,
                                onPressed: onPatients,
                                icon: const Icon(Icons.people_alt_rounded, size: 18),
                                label: const Text('Ver pacientes'),
                              ),
                            ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Circulo extends StatelessWidget {
  const _Circulo({required this.diametro, required this.alpha});

  final double diametro;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}
