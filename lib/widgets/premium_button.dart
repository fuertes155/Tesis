import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Botón premium con gradiente lineal, sombra dinámica y efecto press.
///
/// Ejemplo:
/// ```dart
/// PremiumButton(
///   label: 'COMENZAR',
///   icon: Icons.play_arrow_rounded,
///   onPressed: () {},
/// )
/// ```
class PremiumButton extends StatefulWidget {
  const PremiumButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.height = 48,
    this.radius = 8,
    this.gradient,
    this.fontSize = 14,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double radius;
  final Gradient? gradient;
  final double fontSize;

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _pressed = true);
    _ctrl.forward();
  }

  void _onTapUp(_) {
    setState(() => _pressed = false);
    _ctrl.reverse();
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final cs = Theme.of(context).colorScheme;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    final gradient =
        widget.gradient ??
        (isDisabled
            ? LinearGradient(
                colors: [
                  cs.primary.withValues(alpha: 0.4),
                  cs.tertiary.withValues(alpha: 0.3),
                ],
              )
            : glass.accentGradient);

    final shadowColor = cs.primary.withValues(alpha: _pressed ? 0.35 : 0.22);
    final shadowBlur = _pressed ? 12.0 : 20.0;
    final shadowOffset = _pressed ? const Offset(0, 4) : const Offset(0, 8);
    final shadowSpread = _pressed ? -2.0 : -4.0;

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: widget.height,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: isDisabled
                  ? []
                  : [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: shadowBlur,
                        spreadRadius: shadowSpread,
                        offset: shadowOffset,
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: Colors.white,
                              size: widget.fontSize + 4,
                            ),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            widget.label,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: widget.fontSize,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
