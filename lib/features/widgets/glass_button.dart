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
              size: size * 0.5,
              color: dark ? Colors.white : AtlasColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
