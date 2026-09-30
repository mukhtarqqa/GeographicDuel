import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../widgets/glass_container.dart';

class PanoramaViewer extends StatefulWidget {
  const PanoramaViewer({
    super.key,
    required this.imageAsset,
    this.solid = false,
  });

  final String imageAsset;
  final bool solid;

  @override
  State<PanoramaViewer> createState() => _PanoramaViewerState();
}

class _PanoramaViewerState extends State<PanoramaViewer> {
  double _panX = 0.0;
  double _panY = 0.0;
  double _scale = 1.0;
  double _baseScale = 1.0;

  void _resetCompass() {
    setState(() {
      _panX = 0.0;
      _panY = 0.0;
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Interactive Gesture Area
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: (details) {
            _baseScale = _scale;
          },
          onScaleUpdate: (details) {
            setState(() {
              _scale = (_baseScale * details.scale).clamp(1.0, 3.2);
              _panX = (_panX - details.focalPointDelta.dx * 0.003).clamp(-1.0, 1.0);
              _panY = (_panY - details.focalPointDelta.dy * 0.003).clamp(-0.4, 0.4);
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: _scale,
                child: Image.asset(
                  widget.imageAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment(_panX, _panY),
                  errorBuilder: (_, error, stack) => const ColoredBox(
                    color: Color(0xff43524b),
                    child: Center(
                      child: Text(
                        'Не удалось загрузить панораму',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ),

              // Subtle Vignette Gradient
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x77000000),
                      Colors.transparent,
                      Color(0x88000000),
                    ],
                    stops: [0.0, 0.35, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Compass / Reset Bearing Widget
        Positioned(
          top: 86,
          right: 16,
          child: Semantics(
            button: true,
            label: 'Сбросить ориентацию на север',
            child: GlassContainer(
              dark: true,
              solid: widget.solid,
              radius: 22,
              padding: EdgeInsets.zero,
              onTap: _resetCompass,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Transform.rotate(
                    angle: _panX * math.pi,
                    child: const Icon(
                      Icons.navigation,
                      size: 22,
                      color: Color(0xffff6b6b),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Hint overlay that fades out
        Positioned(
          bottom: 24,
          left: 16,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_outlined, size: 14, color: Colors.white70),
                  SizedBox(width: 5),
                  Text(
                    'Вращайте и приближайте панораму',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
