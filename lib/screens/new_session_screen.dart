import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class NewSessionScreen extends StatelessWidget {
  final int? patientId;

  const NewSessionScreen({super.key, this.patientId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF1A237E);
    final pid = patientId;
    if (pid != null) {
      ApiService().setCurrentPatientId(pid);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Nueva Sesión',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const SizedBox(height: 16),
          Text(
            'SELECCIONE BATERÍA',
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elija el protocolo de evaluación que desea aplicar al paciente.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 40),
          _BatteryCard(
            title: 'Protocolo Integral',
            description: 'Evaluación completa de funciones cognitivas principales.',
            icon: Icons.psychology_outlined,
            color: primaryColor,
            onTap: () => context.push('/test_selector'),
          ),
          const SizedBox(height: 16),
          _BatteryCard(
            title: 'Atención y Memoria',
            description: 'Enfoque específico en retención y procesos atencionales.',
            icon: Icons.memory_outlined,
            color: const Color(0xFF0F172A),
            onTap: () => context.push('/test_selector'),
          ),
          _BatteryCard(
            title: 'Screening Rápido',
            description: 'Evaluación breve para detección temprana.',
            icon: Icons.speed_outlined,
            color: const Color(0xFF64748B),
            onTap: () => context.push('/test_selector'),
          ),
        ],
      ),
    );
  }
}

class _BatteryCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BatteryCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFCBD5E1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
