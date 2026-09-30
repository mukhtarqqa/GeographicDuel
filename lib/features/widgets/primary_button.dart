import 'package:flutter/material.dart';
import '../../core/theme/atlas_theme.dart';
import 'glass_container.dart';

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.icon,
    this.label,
    required this.onPressed,
    this.dark = true,
    this.solid = false,
    this.size = 46,
  });

  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  final bool dark;
  final bool solid;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GlassContainer(
        dark: dark,
        solid: solid,
        radius: size / 2,
        padding: EdgeInsets.zero,
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(
              icon,
              size: size * 0.48,
              color: dark ? Colors.white : AtlasColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.light = false,
    this.accentColor,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool light;
  final Color? accentColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bg = accentColor ?? (light ? Colors.white : AtlasColors.green);
    final fg = light ? AtlasColors.ink : Colors.white;

    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            decoration: BoxDecoration(
              color: onPressed == null
                  ? (light ? Colors.white38 : AtlasColors.line)
                  : bg,
              borderRadius: BorderRadius.circular(999),
              boxShadow: onPressed == null
                  ? null
                  : [
                      BoxShadow(
                        color: bg.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fg,
                    ),
                  )
                else ...[
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: onPressed == null ? AtlasColors.muted : fg,
                      ),
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      icon,
                      size: 18,
                      color: onPressed == null ? AtlasColors.muted : fg,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
