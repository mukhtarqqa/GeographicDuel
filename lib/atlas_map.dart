import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'duel_logic.dart';

/// An offline overview map, with actual Natural Earth geography projected by
/// d3-geo during asset preparation. No tile service or map API key is needed.
class AtlasGeometry {
  AtlasGeometry(this.countries, this.grid);
  final List<Path> countries;
  final List<Path> grid;
  static AtlasGeometry? cached;
  static Future<AtlasGeometry>? _loading;
  static Future<AtlasGeometry> load() async {
    if (cached != null) return cached!;
    if (_loading != null) return _loading!;
    _loading = _read();
    cached = await _loading;
    return cached!;
  }
  static Future<AtlasGeometry> _read() async {
    final data =
        jsonDecode(await rootBundle.loadString('assets/world-map.json'))
            as Map<String, dynamic>;
    Path path(List<dynamic> rings, bool close) {
      final p = Path()..fillType = PathFillType.evenOdd;
      for (final ring in rings) {
        if ((ring as List).isEmpty) continue;
        p.moveTo(
          (ring[0][0] as num).toDouble(),
          (ring[0][1] as num).toDouble(),
        );
        for (final point in ring.skip(1)) {
          p.lineTo((point[0] as num).toDouble(), (point[1] as num).toDouble());
        }
        if (close) p.close();
      }
      return p;
    }

    return AtlasGeometry(
      (data['countries'] as List).map((r) => path(r as List, true)).toList(),
      [path(data['grid'] as List, false)],
    );
  }
}

class AtlasProjection {
  static const width = 720.0, height = 480.0;
  static const scale = width / (2 * math.pi);
  static Offset project(GeoPoint p) => Offset(
    360 + p.longitude * math.pi / 180 * scale,
    240 -
        math.log(
              math.tan(
                math.pi / 4 + p.latitude.clamp(-85.051, 85.051) * math.pi / 360,
              ),
            ) *
            scale,
  );
  static GeoPoint invert(Offset p) => GeoPoint(
    ((2 * math.atan(math.exp((240 - p.dy) / scale)) - math.pi / 2) *
            180 /
            math.pi)
        .clamp(-85.051, 85.051)
        .toDouble(),
    ((p.dx - 360) / scale * 180 / math.pi).clamp(-180, 180).toDouble(),
  );
}

class AtlasMap extends StatefulWidget {
  const AtlasMap({
    super.key,
    this.selected,
    this.onSelect,
    this.result,
    this.target,
    this.opponent,
  });
  final GeoPoint? selected;
  final ValueChanged<GeoPoint>? onSelect;
  final RoundResult? result;
  final GeoPoint? target;
  final GeoPoint? opponent;
  @override
  State<AtlasMap> createState() => _AtlasMapState();
}

class _AtlasMapState extends State<AtlasMap> {
  final _controller = TransformationController();
  Size? _viewport;
  double _minScale = .4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fit(Size size) {
    _minScale = math.min(size.width / 720, size.height / 480);
    GeoPoint center = const GeoPoint(15, 0);
    double scale = _minScale;
    final activeTarget = widget.target ?? (widget.result != null ? RoundResult.target : null);
    final activeOpponent = widget.opponent ?? (widget.result != null ? RoundResult.opponent : null);
    final activeGuess = widget.selected ?? widget.result?.guess;

    if (activeTarget != null) {
      final points = [
        activeTarget,
        if (activeOpponent != null) activeOpponent,
        if (activeGuess != null) activeGuess,
      ].map(AtlasProjection.project).toList();
      final left = points.map((p) => p.dx).reduce(math.min);
      final right = points.map((p) => p.dx).reduce(math.max);
      final top = points.map((p) => p.dy).reduce(math.min);
      final bottom = points.map((p) => p.dy).reduce(math.max);
      scale = math
          .min(
            (size.width - 76) / math.max(60, right - left),
            (size.height - 76) / math.max(55, bottom - top),
          )
          .clamp(_minScale, 5.0);
      center = AtlasProjection.invert(
        Offset((left + right) / 2, (top + bottom) / 2),
      );
    }
    final projected = AtlasProjection.project(center);
    _controller.value = Matrix4.identity()
      ..setTranslationRaw(
        size.width / 2 - projected.dx * scale,
        size.height / 2 - projected.dy * scale,
        0,
      )
      ..scaleByDouble(scale, scale, 1.0, 1.0);
  }

  void _zoom(double factor) {
    if (_viewport == null) return;
    final center = Offset(_viewport!.width / 2, _viewport!.height / 2);
    final scene = _controller.toScene(center);
    final scale = (_controller.value.getMaxScaleOnAxis() * factor).clamp(
      _minScale,
      12.0,
    );
    _controller.value = Matrix4.identity()
      ..setTranslationRaw(center.dx - scene.dx * scale, center.dy - scene.dy * scale, 0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      if (_viewport != size) {
        _viewport = size;
        _fit(size);
      }
      return ColoredBox(
        color: const Color(0xffe5ebe6),
        child: Stack(
          children: [
            FutureBuilder<AtlasGeometry>(
              initialData: AtlasGeometry.cached,
              future: AtlasGeometry.load(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Не удалось загрузить карту'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return InteractiveViewer(
                  transformationController: _controller,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(480),
                  minScale: _minScale,
                  maxScale: 12,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: widget.onSelect == null
                        ? null
                        : (details) {
                            final p = details.localPosition;
                            if (p.dx >= 0 &&
                                p.dx <= 720 &&
                                p.dy >= 0 &&
                                p.dy <= 480) {
                              widget.onSelect!(AtlasProjection.invert(p));
                            }
                          },
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => CustomPaint(
                        size: const Size(720, 480),
                        painter: _MapPainter(
                          snapshot.data!,
                          selected: widget.selected,
                          result: widget.result,
                          target: widget.target,
                          opponent: widget.opponent,
                          zoom: _controller.value.getMaxScaleOnAxis(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (widget.onSelect != null)
              Positioned(
                top: 10,
                right: 10,
                child: Column(
                  children: [
                    _zoomButton(Icons.add, 'Приблизить', () => _zoom(1.8)),
                    const SizedBox(height: 6),
                    _zoomButton(Icons.remove, 'Отдалить', () => _zoom(1 / 1.8)),
                  ],
                ),
              ),
            Positioned(
              left: 9,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xeef4f3ed),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Natural Earth · обзорная карта',
                  style: TextStyle(fontSize: 9, color: Color(0xff64746c)),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _zoomButton(IconData icon, String label, VoidCallback callback) =>
      Material(
        color: const Color(0xeef4f3ed),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: label,
          onPressed: callback,
          icon: Icon(icon, size: 20),
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        ),
      );
}

class _MapPainter extends CustomPainter {
  _MapPainter(
    this.geometry, {
    this.selected,
    this.result,
    this.target,
    this.opponent,
    required this.zoom,
  });
  final AtlasGeometry geometry;
  final GeoPoint? selected;
  final RoundResult? result;
  final GeoPoint? target;
  final GeoPoint? opponent;
  final double zoom;
  static const green = Color(0xff315e4c), rust = Color(0xffad633e);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xffcbd5cd)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .5 / zoom;
    for (final path in geometry.grid) {
      canvas.drawPath(path, grid);
    }
    final fill = Paint()..color = const Color(0xffc7d1c0);
    final border = Paint()
      ..color = const Color(0xfff4f3ed)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7 / zoom;
    for (final path in geometry.countries) {
      canvas.drawPath(path, fill);
      canvas.drawPath(path, border);
    }
    void marker(
      GeoPoint point,
      Color color,
      String label, {
      bool target = false,
    }) {
      final center = AtlasProjection.project(point);
      canvas.drawCircle(
        center,
        12 / zoom,
        Paint()..color = color.withValues(alpha: .16),
      );
      if (target) {
        final r = 6 / zoom;
        canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy - r)
            ..lineTo(center.dx + r, center.dy)
            ..lineTo(center.dx, center.dy + r)
            ..lineTo(center.dx - r, center.dy)
            ..close(),
          Paint()..color = color,
        );
      } else {
        canvas.drawCircle(center, 6 / zoom, Paint()..color = Colors.white);
        canvas.drawCircle(center, 4 / zoom, Paint()..color = color);
      }
      if (label.isNotEmpty) {
        final painter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: const Color(0xff233d35),
              fontSize: 11 / zoom,
              backgroundColor: const Color(0xcceef2e6),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(canvas, center - Offset(painter.width / 2, 24 / zoom));
      }
    }

    final activeTarget = target ?? (result != null ? RoundResult.target : null);
    final activeOpponent = opponent ?? (result != null ? RoundResult.opponent : null);
    final activeGuess = selected ?? result?.guess;

    if (activeTarget != null) {
      void route(GeoPoint point, Color color) {
        canvas.drawLine(
          AtlasProjection.project(point),
          AtlasProjection.project(activeTarget),
          Paint()
            ..color = color.withValues(alpha: .8)
            ..strokeWidth = 1.5 / zoom,
        );
      }

      if (activeGuess != null) {
        route(activeGuess, green);
        marker(activeGuess, green, 'Вы');
      }
      if (activeOpponent != null) {
        route(activeOpponent, rust);
        marker(activeOpponent, rust, 'Соперник');
      }
      marker(activeTarget, const Color(0xffa1b456), 'Цель', target: true);
    } else {
      if (selected != null) marker(selected!, green, 'Вы');
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.geometry != geometry ||
      old.selected != selected ||
      old.result != result ||
      old.target != target ||
      old.opponent != opponent ||
      old.zoom != zoom;
}
