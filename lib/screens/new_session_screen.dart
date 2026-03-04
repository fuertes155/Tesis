import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NewSessionScreen extends StatelessWidget {
  const NewSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Nueva Sesión'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'Seleccione Batería',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Elija el conjunto de pruebas a aplicar',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _BatteryCard(
            title: 'Batería Neuropsicológica Completa',
            description: 'Evaluación integral de todas las funciones cognitivas principales.',
            icon: Icons.psychology_rounded,
            color: Colors.indigo,
            onTap: () => context.push('/test_selector'),
          ),
          const SizedBox(height: 16),
          _BatteryCard(
            title: 'Atención y Memoria',
            description: 'Enfoque específico en procesos atencionales y retención.',
            icon: Icons.memory_rounded,
            color: Colors.teal,
            onTap: () => context.push('/test_selector'),
          ),
          const SizedBox(height: 16),
          _BatteryCard(
            title: 'Screening Rápido',
            description: 'Evaluación breve para detección temprana de deterioro.',
            icon: Icons.speed_rounded,
            color: Colors.orange,
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
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
