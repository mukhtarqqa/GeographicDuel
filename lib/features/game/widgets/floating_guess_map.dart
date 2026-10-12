import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../domain/models/geo_point.dart';
import '../../../atlas_map.dart';

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

class _FloatingGuessMapState extends State<FloatingGuessMap>
    with SingleTickerProviderStateMixin {
  GeoPoint? _selectedPoint;
  MapSizeMode _mode = MapSizeMode.expanded;
  bool _showCoordsInput = false;
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();
  String? _coordsError;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialGuess;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
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
    final isSmallScreen = screenSize.width < 420;

    double mapWidth;
    double mapHeight;

    switch (_mode) {
      case MapSizeMode.collapsed:
        mapWidth = isSmallScreen ? 180 : 230;
        mapHeight = isSmallScreen ? 130 : 160;
        break;
      case MapSizeMode.expanded:
        mapWidth = math.min(screenSize.width - 24, 480);
        mapHeight = math.min(screenSize.height * 0.48, 380);
        break;
      case MapSizeMode.fullscreen:
        mapWidth = screenSize.width - 20;
        mapHeight = screenSize.height - 120;
        break;
    }

    final isCollapsed = _mode == MapSizeMode.collapsed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: mapWidth,
      height: mapHeight,
      margin: const EdgeInsets.only(right: 12, bottom: 12),
      decoration: BoxDecoration(
        color: widget.solid
            ? const Color(0xff18221f)
            : const Color(0xe6131c19),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.opponentHasGuessed
              ? const Color(0xfff59e0b).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.22),
          width: widget.opponentHasGuessed ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.opponentHasGuessed
                ? const Color(0xfff59e0b).withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.4),
            blurRadius: widget.opponentHasGuessed ? 22 : 16,
            spreadRadius: widget.opponentHasGuessed ? 2 : 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              // 1. Header controls
              _buildHeader(isCollapsed: isCollapsed),

              // 2. Urgent Opponent Alert Bar (if opponent answered)
              if (widget.opponentHasGuessed && !isCollapsed) ...[
                const SizedBox(height: 6),
                _buildOpponentAlertBanner(),
              ],

              const SizedBox(height: 8),

              // 3. Map Viewport Canvas
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      AtlasMap(
                        selected: _selectedPoint,
                        onSelect: isCollapsed
                            ? (point) => setState(() => _mode = MapSizeMode.expanded)
                            : _onMapSelect,
                      ),

                      // If collapsed: tap-to-expand overlay badge
                      if (isCollapsed)
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => setState(() => _mode = MapSizeMode.expanded),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.65),
                                    ],
                                  ),
                                ),
                                alignment: Alignment.bottomCenter,
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff10b981),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black38, blurRadius: 4),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.touch_app, size: 13, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        'Үлкейту',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Manual coordinates input overlay
                      if (_showCoordsInput && !isCollapsed)
                        _buildCoordsInputOverlay(),
                    ],
                  ),
                ),
              ),

              // 4. Footer: Coordinates & Confirm Button
              if (!isCollapsed) ...[
                const SizedBox(height: 10),
                _buildActionFooter(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required bool isCollapsed}) {
    if (isCollapsed) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.map_outlined, size: 14, color: Color(0xff10b981)),
              const SizedBox(width: 5),
              Text(
                _selectedPoint != null ? '📍 НҮКТЕ ҚОЙЫЛДЫ' : 'КАРТА',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: _toggleSize,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.open_in_full, size: 14, color: Colors.white),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        // Left Title or Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.public, size: 14, color: Color(0xff34d399)),
              SizedBox(width: 5),
              Text(
                'БОЛЖАМ КАРТАСЫ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),

        // Right Control Buttons
        _buildHeaderToolButton(
          icon: _showCoordsInput ? Icons.close : Icons.edit_location_alt_outlined,
          tooltip: 'Координаттар',
          isActive: _showCoordsInput,
          onTap: () => setState(() => _showCoordsInput = !_showCoordsInput),
        ),
        const SizedBox(width: 6),
        _buildHeaderToolButton(
          icon: _mode == MapSizeMode.fullscreen ? Icons.close_fullscreen : Icons.fullscreen,
          tooltip: _mode == MapSizeMode.fullscreen ? 'Кішірейту' : 'Толық экранға',
          isActive: _mode == MapSizeMode.fullscreen,
          onTap: _toggleSize,
        ),
        const SizedBox(width: 6),
        _buildHeaderToolButton(
          icon: Icons.keyboard_arrow_down,
          tooltip: 'Жию',
          onTap: _collapse,
        ),
      ],
    );
  }

  Widget _buildHeaderToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xff10b981).withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive
                    ? const Color(0xff10b981)
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isActive ? const Color(0xff34d399) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpponentAlertBanner() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xffdc2626).withValues(alpha: 0.85 + 0.15 * _pulseCtrl.value),
                const Color(0xfff59e0b).withValues(alpha: 0.85 + 0.15 * _pulseCtrl.value),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffdc2626).withValues(alpha: 0.3 * _pulseCtrl.value),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt, size: 14, color: Colors.white),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Қарсылас белгі қойды! 15 секунд қалды!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionFooter() {
    final hasPoint = _selectedPoint != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Point Status info chip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasPoint ? Icons.location_on : Icons.touch_app_outlined,
                size: 14,
                color: hasPoint ? const Color(0xff34d399) : const Color(0xff94a3b8),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hasPoint
                      ? _selectedPoint!.label
                      : 'Картадан кез келген нүктені түртіңіз',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: hasPoint ? Colors.white : const Color(0xff94a3b8),
                    fontWeight: hasPoint ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (hasPoint)
                InkWell(
                  onTap: () => setState(() => _selectedPoint = null),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.clear, size: 14, color: Colors.white60),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Full-width Confirm Guess Button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: hasPoint
                ? () => widget.onGuessConfirmed(_selectedPoint!)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff10b981),
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.12),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white38,
              elevation: hasPoint ? 6 : 0,
              shadowColor: const Color(0xff10b981).withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: hasPoint
                      ? const Color(0xff34d399)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasPoint ? Icons.check_circle_rounded : Icons.place_outlined,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  hasPoint ? 'БОЛЖАМДЫ РАСТАУ' : 'НҮКТЕНІ БЕЛГІЛЕҢІЗ',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoordsInputOverlay() {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xff18221f),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 12),
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
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'Ендік (N/S)',
                      labelStyle: const TextStyle(color: Colors.white60, fontSize: 11),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lonCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'Бойлық (E/W)',
                      labelStyle: const TextStyle(color: Colors.white60, fontSize: 11),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.check, color: Color(0xff10b981)),
                  tooltip: 'Координаттарды қолдану',
                  onPressed: _applyManualCoords,
                ),
              ],
            ),
            if (_coordsError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _coordsError!,
                  style: const TextStyle(fontSize: 11, color: Color(0xfff87171)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
