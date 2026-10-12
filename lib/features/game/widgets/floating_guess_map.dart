import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/atlas_theme.dart';
import '../../../domain/models/geo_point.dart';
import '../../../atlas_map.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/primary_button.dart';

enum MapSizeMode {
  collapsed,
  expanded,
  fullscreen,
}

class FloatingGuessMap extends StatefulWidget {
  const FloatingGuessMap({
    super.key,
    required this.initialGuess,
    required this.onGuessConfirmed,
    this.opponentHasGuessed = false,
    this.solid = false,
  });

  final GeoPoint? initialGuess;
  final ValueChanged<GeoPoint> onGuessConfirmed;
  final bool opponentHasGuessed;
  final bool solid;

  @override
  State<FloatingGuessMap> createState() => _FloatingGuessMapState();
}

class _FloatingGuessMapState extends State<FloatingGuessMap> {
  GeoPoint? _selectedPoint;
  MapSizeMode _mode = MapSizeMode.expanded;
  bool _showCoordsInput = false;
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();
  String? _coordsError;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialGuess;
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lonCtrl.dispose();
    super.dispose();
  }

  void _onMapSelect(GeoPoint point) {
    setState(() {
      _selectedPoint = point;
      _coordsError = null;
    });
  }

  void _applyManualCoords() {
    final lat = double.tryParse(_latCtrl.text.replaceAll(',', '.'));
    final lon = double.tryParse(_lonCtrl.text.replaceAll(',', '.'));
    if (lat == null || lon == null || !GeoPoint(lat, lon).isValid) {
      setState(() => _coordsError = 'Ендік: −90…90, бойлық: −180…180');
      return;
    }
    _onMapSelect(GeoPoint(lat, lon));
    setState(() => _showCoordsInput = false);
    FocusScope.of(context).unfocus();
  }

  void _toggleSize() {
    setState(() {
      if (_mode == MapSizeMode.collapsed) {
        _mode = MapSizeMode.expanded;
      } else if (_mode == MapSizeMode.expanded) {
        _mode = MapSizeMode.fullscreen;
      } else {
        _mode = MapSizeMode.expanded;
      }
    });
  }

  void _collapse() {
    setState(() {
      _mode = MapSizeMode.collapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    double mapWidth;
    double mapHeight;

    switch (_mode) {
      case MapSizeMode.collapsed:
        mapWidth = isSmallScreen ? 160 : 210;
        mapHeight = isSmallScreen ? 120 : 150;
        break;
      case MapSizeMode.expanded:
        mapWidth = math.min(screenSize.width - 24, 460);
        mapHeight = math.min(screenSize.height * 0.44, 340);
        break;
      case MapSizeMode.fullscreen:
        mapWidth = screenSize.width - 24;
        mapHeight = screenSize.height - 110;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: mapWidth,
      height: mapHeight,
      margin: const EdgeInsets.only(right: 12, bottom: 12),
      child: GlassContainer(
        dark: false,
        solid: widget.solid,
        radius: 20,
        padding: const EdgeInsets.all(8),
        borderColor: widget.opponentHasGuessed
            ? const Color(0xffff9900).withValues(alpha: 0.8)
            : null,
        child: Column(
          children: [
            // Top Controls Bar (Header)
            _buildHeader(isSmall: _mode == MapSizeMode.collapsed),

            // Map canvas
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    AtlasMap(
                      selected: _selectedPoint,
                      onSelect: _mode == MapSizeMode.collapsed
                          ? (point) => setState(() => _mode = MapSizeMode.expanded)
                          : _onMapSelect,
                    ),

                    if (_mode == MapSizeMode.collapsed)
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _mode = MapSizeMode.expanded),
                          ),
                        ),
                      ),

                    if (_showCoordsInput && _mode != MapSizeMode.collapsed)
                      _buildCoordsInputOverlay(),
                  ],
                ),
              ),
            ),

            if (_mode != MapSizeMode.collapsed) ...[
              const SizedBox(height: 8),
              // Guess Button & Location Label
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedPoint == null
                          ? 'Белгі қою үшін картаны түртіңіз'
                          : _selectedPoint!.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AtlasColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Flexible(
                    child: PrimaryButton(
                      label: _selectedPoint == null ? 'Белгі қойыңыз' : 'Жауап беру',
                      icon: Icons.check_circle_outline,
                      accentColor: AtlasColors.green,
                      onPressed: _selectedPoint == null
                          ? null
                          : () => widget.onGuessConfirmed(_selectedPoint!),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({required bool isSmall}) {
    if (isSmall) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'КАРТА',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AtlasColors.ink,
                letterSpacing: 1,
              ),
            ),
            InkWell(
              onTap: _toggleSize,
              child: const Icon(Icons.open_in_full, size: 16, color: AtlasColors.ink),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Row(
        children: [
          if (widget.opponentHasGuessed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xfffff1f0),
                border: Border.all(color: const Color(0xffffccc7)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, size: 12, color: Color(0xffff4d4f)),
                  SizedBox(width: 3),
                  Text(
                    'Қарсылас жауап берді!',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xffcf1322),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            const Expanded(
              child: Text(
                'Картадан нүктені таңдаңыз',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AtlasColors.ink,
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              _showCoordsInput ? Icons.close : Icons.edit_location_alt_outlined,
              size: 18,
            ),
            tooltip: 'Координаттарды енгізу',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onPressed: () => setState(() => _showCoordsInput = !_showCoordsInput),
          ),
          IconButton(
            icon: Icon(
              _mode == MapSizeMode.fullscreen ? Icons.close_fullscreen : Icons.fullscreen,
              size: 20,
            ),
            tooltip: _mode == MapSizeMode.fullscreen ? 'Кішірейту' : 'Толық экранға',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onPressed: _toggleSize,
          ),
          IconButton(
            icon: const Icon(Icons.remove, size: 20),
            tooltip: 'Жию',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onPressed: _collapse,
          ),
        ],
      ),
    );
  }

  Widget _buildCoordsInputOverlay() {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Ендік (N/S)',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lonCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Бойлық (E/W)',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.check, color: AtlasColors.green),
                  tooltip: 'Координаттарды қолдану',
                  onPressed: _applyManualCoords,
                ),
              ],
            ),
            if (_coordsError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _coordsError!,
                  style: const TextStyle(fontSize: 10, color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
