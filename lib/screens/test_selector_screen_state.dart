part of 'test_selector_screen.dart';

class TestSelectorScreenState extends State<TestSelectorScreen> {
  final Map<String, _TestInfo> _tests = {
    'Prueba de Memoria Visual': _TestInfo(
      icon: Icons.visibility_outlined,
      description: 'Retención y reconocimiento de patrones visuales.',
      duration: 8,
      domain: 'Memoria',
      domainColor: const Color(0xFF8B5CF6),
    ),
    'Prueba de Atención Sostenida': _TestInfo(
      icon: Icons.timer_outlined,
      description: 'Tiempo de reacción y atención focalizada.',
      duration: 6,
      domain: 'Atención',
      domainColor: const Color(0xFF0EA5E9),
    ),
    'Prueba de Fluidez Verbal': _TestInfo(
      icon: Icons.mic_none_outlined,
      description: 'Producción de palabras y lenguaje expresivo.',
      duration: 5,
      domain: 'Lenguaje',
      domainColor: const Color(0xFF10B981),
    ),
    'Prueba de Funciones Ejecutivas (Stroop)': _TestInfo(
      icon: Icons.psychology_outlined,
      description: 'Inhibición cognitiva y flexibilidad mental.',
      duration: 7,
      domain: 'F. Ejecutivas',
      domainColor: const Color(0xFFF59E0B),
    ),
  };

  late final Map<String, bool> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {for (final k in _tests.keys) k: false};
    if (widget.initialSelection != null) {
      for (final k in widget.initialSelection!) {
        if (_selected.containsKey(k)) {
          _selected[k] = true;
        }
      }
    }
  }

  int get _totalMinutes => _tests.entries
      .where((e) => _selected[e.key] == true)
      .fold(0, (sum, e) => sum + e.value.duration);

  int get _selectedCount => _selected.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final r = context.radii;
    final spacing = context.spacing;
    final glass = context.glass;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: cs.surfaceContainerLowest,
        elevation: 0,
        title: const Text('Configurar Sesión'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // ── Header informativo premium ─────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(spacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.surfaceContainerLowest,
                  cs.surfaceContainerLowest.withValues(alpha: 0.7),
                ],
              ),
              border: Border(
                bottom: BorderSide(color: cs.outlineVariant, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          Icon(Icons.tune_rounded, color: cs.primary, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SELECCIÓN DE PRUEBAS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.xs),
                Text(
                  'Personalice el protocolo de evaluación cognitiva.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (_selectedCount > 0) ...[
                  SizedBox(height: spacing.md),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.all(spacing.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.primary.withValues(alpha: 0.10),
                          cs.tertiary.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: r.radiusMd,
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_outlined,
                            color: cs.primary, size: 18),
                        SizedBox(width: spacing.sm),
                        Text(
                          '$_selectedCount prueba${_selectedCount == 1 ? '' : 's'} seleccionada${_selectedCount == 1 ? '' : 's'}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: glass.accentGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '~$_totalMinutes min',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 200.ms).scale(
                      begin: const Offset(0.97, 0.97)),
                ],
              ],
            ),
          ),

          // ── Lista de pruebas ───────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(spacing.lg),
              physics: const BouncingScrollPhysics(),
              itemCount: _tests.length,
              separatorBuilder: (_, __) => SizedBox(height: spacing.sm),
              itemBuilder: (context, index) {
                final key = _tests.keys.elementAt(index);
                final info = _tests[key]!;
                final isSelected = _selected[key]!;

                return _TestCard(
                  title: key,
                  info: info,
                  isSelected: isSelected,
                  onChanged: (v) =>
                      setState(() => _selected[key] = v ?? false),
                ).animate()
                    .fadeIn(delay: Duration(milliseconds: index * 70))
                    .slideY(begin: 0.08);
              },
            ),
          ),

          // ── Botón Comenzar premium ─────────────────────────────────────────
          Container(
            padding: EdgeInsets.all(spacing.lg),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              border: Border(top: BorderSide(color: cs.outlineVariant)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: PremiumButton(
                label: _selectedCount > 0
                    ? 'COMENZAR EVALUACIÓN  (~$_totalMinutes min)'
                    : 'SELECCIONA AL MENOS UNA PRUEBA',
                icon: Icons.play_arrow_rounded,
                onPressed: _selectedCount > 0
                    ? () {
                        final routes = <String>[];
                        if (_selected['Prueba de Memoria Visual'] == true) {
                          routes.add('/game_memory');
                        }
                        if (_selected['Prueba de Atención Sostenida'] == true) {
                          routes.add('/game_reaction');
                        }
                        if (_selected['Prueba de Fluidez Verbal'] == true) {
                          routes.add('/game_fluency');
                        }
                        if (_selected['Prueba de Funciones Ejecutivas (Stroop)'] ==
                            true) {
                          routes.add('/game_stroop');
                        }
                        if (routes.isEmpty) {
                          context.push('/test_placeholder');
                          return;
                        }
                        context.push('/game_flow', extra: {'routes': routes});
                      }
                    : null,
                gradient: _selectedCount > 0
                    ? null
                    : LinearGradient(
                        colors: [
                          const Color(0xFF0A7EA4).withValues(alpha: 0.35),
                          const Color(0xFF38BDF8).withValues(alpha: 0.20),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modelo ────────────────────────────────────────────────────────────────────

class _TestInfo {
  final IconData icon;
  final String description;
  final int duration;
  final String domain;
  final Color domainColor;
  const _TestInfo({
    required this.icon,
    required this.description,
    required this.duration,
    required this.domain,
    required this.domainColor,
  });
}

// ── Test Card Premium ─────────────────────────────────────────────────────────

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.title,
    required this.info,
    required this.isSelected,
    required this.onChanged,
  });

  final String title;
  final _TestInfo info;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final r = context.radii;
    final spacing = context.spacing;
    final glass = context.glass;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withValues(alpha: 0.10),
                  cs.tertiary.withValues(alpha: 0.05),
                ],
              )
            : glass.cardGradient,
        borderRadius: r.radiusMd,
        border: Border.all(
          color: isSelected ? cs.primary.withValues(alpha: 0.40) : glass.borderColor,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ]
            : context.premiumShadows,
      ),
      child: InkWell(
        onTap: () => onChanged(!isSelected),
        borderRadius: r.radiusMd,
        splashColor: cs.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Row(
            children: [
              // Ícono del test
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [cs.primary, cs.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            info.domainColor.withValues(alpha: 0.15),
                            info.domainColor.withValues(alpha: 0.08),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.30),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Icon(
                  info.icon,
                  color: isSelected ? Colors.white : info.domainColor,
                  size: 26,
                ),
              ),
              SizedBox(width: spacing.md),

              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isSelected ? cs.primary : cs.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: spacing.xs - 4),
                    Text(
                      info.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: spacing.xs),
                    Row(
                      children: [
                        _DomainPill(
                          text: info.domain,
                          color: info.domainColor,
                        ),
                        const SizedBox(width: 6),
                        _DomainPill(
                          text: '~${info.duration} min',
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Checkbox premium
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [cs.primary, cs.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : cs.outlineVariant,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DomainPill extends StatelessWidget {
  const _DomainPill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color.withValues(alpha: 0.90),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
