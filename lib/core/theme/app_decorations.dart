import 'package:flutter/material.dart';
import 'dart:ui';

class AppDecorations {
  static BoxDecoration meshGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    
    return BoxDecoration(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      gradient: RadialGradient(
        center: const Alignment(-0.8, -0.6),
        radius: 1.5,
        colors: [
          primary.withValues(alpha: isDark ? 0.15 : 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ),
    );
  }

  static Widget meshBackground({required Widget child}) {
    return Stack(
      children: [
        Positioned.fill(
          child: Builder(
            builder: (context) => Container(
              decoration: meshGradient(context),
            ),
          ),
        ),
        // Sutiles orbes de luz
        Positioned(
          top: -100,
          right: -100,
          child: Builder(
            builder: (context) => Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  static InputDecoration glassInput({
    required String label,
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(prefixIcon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
    );
  }

  static BoxDecoration premiumCard(BuildContext context, {double radius = 16}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
