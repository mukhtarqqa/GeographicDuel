import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../widgets/glass_container.dart';

class PanoramaViewer extends StatefulWidget {
  const PanoramaViewer({
    super.key,
    this.imageAsset = 'assets/scene.jpg',
    this.imageUrl = '',
    this.solid = false,
  });

  final String imageAsset;
  final String imageUrl;
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

  Widget _buildImage() {
    final hasNetworkUrl = widget.imageUrl.isNotEmpty && widget.imageUrl.startsWith('http');

    if (hasNetworkUrl) {
      return Image.network(
        widget.imageUrl,
        fit: BoxFit.cover,
        alignment: Alignment(_panX, _panY),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xff1b2622),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Панорама жүктелуде...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        errorBuilder: (_, error, stack) => _buildFallbackImage(),
      );
    }

    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      widget.imageAsset,
      fit: BoxFit.cover,
      alignment: Alignment(_panX, _panY),
      errorBuilder: (_, error, stack) => Container(
        color: const Color(0xff43524b),
        child: const Center(
          child: Text(
            'Панораманы жүктеу мүмкін болмады',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Interactive Gesture Area
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: () {
            setState(() {
              _scale = _scale > 1.4 ? 1.0 : 2.2;
            });
          },
          onScaleStart: (details) {
            _baseScale = _scale;
          },
          onScaleUpdate: (details) {
            setState(() {
              _scale = (_baseScale * details.scale).clamp(1.0, 3.5);
              _panX = (_panX - details.focalPointDelta.dx * 0.003).clamp(-1.0, 1.0);
              _panY = (_panY - details.focalPointDelta.dy * 0.003).clamp(-0.4, 0.4);
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedScale(
                scale: _scale,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                child: _buildImage(),
              ),

              // Subtle Vignette Gradient
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x88000000),
                      Colors.transparent,
                      Color(0x99000000),
                    ],
                    stops: [0.0, 0.35, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Top Left Exploration Mode Tag
        Positioned(
          top: 86,
          left: 16,
          child: GlassContainer(
            dark: true,
            solid: widget.solid,
            radius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.threed_rotation_rounded, size: 14, color: Color(0xff34d399)),
                SizedBox(width: 5),
                Text(
                  '360° Интерактивті шолу',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Side Floating Camera & Zoom Controls Column
        Positioned(
          top: 86,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Compass / Reset Bearing Widget
              Semantics(
                button: true,
                label: 'Солтүстікке бағыттау',
                child: GlassContainer(
                  dark: true,
                  solid: widget.solid,
                  radius: 20,
                  padding: EdgeInsets.zero,
                  onTap: _resetCompass,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Transform.rotate(
                        angle: _panX * math.pi,
                        child: const Icon(
                          Icons.navigation,
                          size: 20,
                          color: Color(0xfff87171),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Zoom In (+)
              GlassContainer(
                dark: true,
                solid: widget.solid,
                radius: 18,
                padding: EdgeInsets.zero,
                onTap: () {
                  setState(() {
                    _scale = (_scale + 0.5).clamp(1.0, 3.5);
                  });
                },
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: Icon(Icons.add, size: 18, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Zoom Out (-)
              GlassContainer(
                dark: true,
                solid: widget.solid,
                radius: 18,
                padding: EdgeInsets.zero,
                onTap: () {
                  setState(() {
                    _scale = (_scale - 0.5).clamp(1.0, 3.5);
                  });
                },
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: Icon(Icons.remove, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
