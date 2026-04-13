part of 'test_selector_screen.dart';

class TestSelectorScreenState extends State<TestSelectorScreen> {
  final Map<String, bool> _selectedTests = {
    'Prueba de Memoria Visual': false,
    'Prueba de Atención Sostenida': false,
    'Prueba de Fluidez Verbal': false,
    'Prueba de Funciones Ejecutivas (Stroop)': false,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final r = context.radii;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: cs.surfaceContainerLowest,
        elevation: 0,
        title: Text(
          'Configurar Sesión',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: spacing.md),
                Text(
                  'SELECCIÓN DE PRUEBAS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: spacing.xs),
                Text(
                  'Personalice el protocolo de evaluación seleccionando las pruebas específicas para este paciente.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: spacing.lg),
              itemCount: _selectedTests.length,
              separatorBuilder: (context, index) => SizedBox(height: spacing.sm),
              itemBuilder: (context, index) {
                final key = _selectedTests.keys.elementAt(index);
                final isSelected = _selectedTests[key]!;

                IconData icon;
                if (key.contains('Memoria')) {
                  icon = Icons.visibility_outlined;
                } else if (key.contains('Atención')) {
                  icon = Icons.timer_outlined;
                } else if (key.contains('Fluidez')) {
                  icon = Icons.mic_none_outlined;
                } else {
                  icon = Icons.psychology_outlined;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primary.withValues(alpha: 0.03)
                        : cs.surfaceContainerLowest,
                    borderRadius: r.radiusMd,
                    border: Border.all(
                      color: isSelected
                          ? cs.primary
                          : cs.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.all(spacing.md),
                    secondary: Container(
                      padding: EdgeInsets.all(spacing.sm),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primary
                            : cs.surfaceContainerHighest,
                        borderRadius: r.radiusSm,
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? cs.onPrimary
                            : cs.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      key,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isSelected
                            ? cs.primary
                            : cs.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    subtitle: Text(
                      'Duración estimada: 5-8 min',
                      style: TextStyle(
                        color: isSelected
                            ? cs.primary.withValues(alpha: 0.6)
                            : cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    value: isSelected,
                    activeColor: cs.primary,
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: r.radiusSm,
                    ),
                    onChanged: (bool? value) {
                      setState(() {
                        _selectedTests[key] = value!;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(spacing.lg),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _selectedTests.containsValue(true)
                    ? () {
                        final routes = <String>[];
                        if (_selectedTests['Prueba de Memoria Visual'] == true) {
                          routes.add('/game_memory');
                        }
                        if (_selectedTests['Prueba de Atención Sostenida'] ==
                            true) {
                          routes.add('/game_reaction');
                        }
                        if (_selectedTests['Prueba de Fluidez Verbal'] == true) {
                          routes.add('/game_fluency');
                        }
                        if (_selectedTests[
                                'Prueba de Funciones Ejecutivas (Stroop)'] ==
                            true) {
                          routes.add('/game_stroop');
                        }
                        if (routes.isEmpty) {
                          context.push('/test_placeholder');
                          return;
                        }
                        context.push(
                          '/game_flow',
                          extra: {'routes': routes},
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: r.radiusSm,
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                child: const Text('COMENZAR EVALUACIÓN'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
