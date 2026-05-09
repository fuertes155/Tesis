import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/api_providers.dart';
import '../providers/theme_provider.dart';
import '../core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = context.spacing;
    final api = ref.watch(apiServiceProvider).value;
    final themeMode = ref.watch(themeProvider);

    final userEmail = api?.currentUsername ?? 'usuario@neuroapp.com';
    final userRole = api?.currentRole ?? 'No definido';
    final userName = userEmail.split('@')[0].toUpperCase();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: cs.surfaceContainerLowest,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con Avatar
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(s.xl),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                border: Border(bottom: BorderSide(color: cs.outlineVariant)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: cs.primary.withValues(alpha: 0.1),
                    child: Text(
                      userName.isNotEmpty ? userName[0] : 'U',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(height: s.md),
                  Text(
                    userName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    userEmail,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: s.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      userRole.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(s.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AJUSTES DE LA APLICACIÓN',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: s.md),
                  
                  // Theme Toggle Tile
                  _buildProfileTile(
                    context,
                    icon: themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    title: 'Modo de Pantalla',
                    subtitle: themeMode == ThemeMode.dark ? 'Oscuro' : 'Claro',
                    trailing: Switch(
                      value: themeMode == ThemeMode.dark,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        ref.read(themeProvider.notifier).toggleTheme();
                      },
                    ),
                  ),

                  SizedBox(height: s.xl),
                  Text(
                    'CUENTA Y SEGURIDAD',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: s.md),

                  _buildProfileTile(
                    context,
                    icon: Icons.lock_outline_rounded,
                    title: 'Cambiar Contraseña',
                    subtitle: 'Actualiza tus credenciales de acceso',
                    onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Función disponible en la próxima versión')),
                      );
                    },
                  ),

                  _buildProfileTile(
                    context,
                    icon: Icons.logout_rounded,
                    title: 'Cerrar Sesión',
                    subtitle: 'Salir de la cuenta actual',
                    color: context.sem.danger,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.go('/');
                    },
                  ),

                  SizedBox(height: s.x2l),
                  Center(
                    child: Text(
                      'NeuroApp Systems v1.0.0\n© 2026 Hospital Central',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final r = context.radii;
    final s = context.spacing;
    final activeColor = color ?? cs.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: s.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: r.radiusMd,
        child: Container(
          padding: EdgeInsets.all(s.md),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: r.radiusMd,
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: activeColor, size: 22),
              ),
              SizedBox(width: s.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color ?? cs.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing else Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
