import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../domain/models/location_item.dart';
import '../../../firebase_options.dart';
import '../../widgets/glass_container.dart';
import 'street_view_iframe.dart';

enum PanoramaMode {
  sphere360,
  streetView,
}

class PanoramaViewer extends StatefulWidget {
  const PanoramaViewer({
    super.key,
    this.location,
    this.imageAsset = 'assets/scene.jpg',
    this.imageUrl = '',
    this.solid = false,
  });

  final LocationItem? location;
  final String imageAsset;
  final String imageUrl;
  final bool solid;

  @override
  State<PanoramaViewer> createState() => _PanoramaViewerState();
}

class _PanoramaViewerState extends State<PanoramaViewer> {
  PanoramaMode _mode = PanoramaMode.sphere360;

  // 360 Panoramic Camera State
  double _yaw = 0.0; // 0.0 to 1.0 (continuous infinite rotation, 1.0 = 360°)
  double _pitch = 0.0; // -0.35 to 0.35 (vertical look angle)
  double _scale = 1.0;
  double _baseScale = 1.0;

  // Image loading for custom 360 painter
  ui.Image? _loadedImage;
  bool _isLoadingImage = false;
  String? _lastLoadedSource;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant PanoramaViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSrc = oldWidget.location?.effectiveImage ?? (oldWidget.imageUrl.isNotEmpty ? oldWidget.imageUrl : oldWidget.imageAsset);
    final newSrc = _effectiveImageSource;
    if (oldSrc != newSrc) {
      _loadImage();
      _resetCamera();
    }
  }

  String get _effectiveImageSource {
    if (widget.location != null) {
      return widget.location!.effectiveImage;
    }
    return widget.imageUrl.isNotEmpty ? widget.imageUrl : widget.imageAsset;
  }

  void _loadImage() {
    final src = _effectiveImageSource;
    if (src == _lastLoadedSource && _loadedImage != null) return;

    _isLoadingImage = true;
    _lastLoadedSource = src;

    final ImageProvider provider = src.startsWith('http')
        ? NetworkImage(src)
        : AssetImage(widget.imageAsset) as ImageProvider;

    final stream = provider.resolve(const ImageConfiguration());
    ImageStreamListener? listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _loadedImage = info.image;
            _isLoadingImage = false;
          });
        }
        stream.removeListener(listener!);
      },
      onError: (dynamic error, StackTrace? stack) {
        if (mounted) {
          // Fallback to local scene.jpg on network error
          final fallbackStream = AssetImage(widget.imageAsset).resolve(const ImageConfiguration());
          ImageStreamListener? fallbackListener;
          fallbackListener = ImageStreamListener((info, _) {
            if (mounted) {
              setState(() {
                _loadedImage = info.image;
                _isLoadingImage = false;
              });
            }
            fallbackStream.removeListener(fallbackListener!);
          });
          fallbackStream.addListener(fallbackListener);
        }
      },
    );
    stream.addListener(listener);
  }

  void _resetCamera() {
    setState(() {
      _yaw = 0.0;
      _pitch = 0.0;
      _scale = 1.0;
    });
  }

  void _openGoogleMapsExternal() {
    final loc = widget.location;
    if (loc == null) return;
    openExternalUrl(loc.googleStreetViewWebUrl);
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.location;
    final apiKey = DefaultFirebaseOptions.web.apiKey;
    final streetViewUrl = loc != null
        ? loc.getGoogleStreetViewEmbedUrl(apiKey)
        : '';

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Primary Viewer Canvas (360° Sphere vs Google Street View)
        if (_mode == PanoramaMode.streetView && streetViewUrl.isNotEmpty)
          _buildGoogleStreetView(streetViewUrl)
        else
          _buildContinuous360Canvas(),

        // 2. Top-Left Dual Mode Switcher
        Positioned(
          top: 86,
          left: 16,
          child: _buildModeSwitcher(),
        ),

        // 3. Right-Side Camera, Zoom & External Controls
        Positioned(
          top: 86,
          right: 16,
          child: _buildRightControlsColumn(),
        ),
      ],
    );
  }

  Widget _buildContinuous360Canvas() {
    return GestureDetector(
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
          // Continuous yaw calculation (never stops at edges!)
          _yaw = (_yaw - details.focalPointDelta.dx * 0.0015 / _scale) % 1.0;
          if (_yaw < 0.0) _yaw += 1.0;

          // Vertical tilt
          _pitch = (_pitch + details.focalPointDelta.dy * 0.001 / _scale).clamp(-0.35, 0.35);
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_loadedImage != null && !_isLoadingImage)
            CustomPaint(
              painter: _EquirectangularPainter(
                image: _loadedImage!,
                yaw: _yaw,
                pitch: _pitch,
                zoom: _scale,
              ),
              size: Size.infinite,
            )
          else
            _buildLoadingState(),

          // Cinematic Vignette Shader
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
    );
  }

  Widget _buildGoogleStreetView(String embedUrl) {
    final viewId = 'streetview-${widget.location?.id ?? "default"}';

    return Stack(
      fit: StackFit.expand,
      children: [
        StreetViewIframe(
          url: embedUrl,
          viewId: viewId,
        ),

        // Hint bar for interactive controls
        Positioned(
          bottom: 110,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app, size: 14, color: Color(0xff34d399)),
                SizedBox(width: 6),
                Text(
                  'Google Street View: 360° бұру және көше бойлап жүру белсенді',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSwitcher() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xee131c19),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 360° Sphere Option
          _buildModeTab(
            title: '360° Сфера',
            icon: Icons.threed_rotation_rounded,
            isSelected: _mode == PanoramaMode.sphere360,
            onTap: () => setState(() => _mode = PanoramaMode.sphere360),
          ),

          // 2. Google Street View Option
          _buildModeTab(
            title: 'Google Street View',
            icon: Icons.streetview,
            isSelected: _mode == PanoramaMode.streetView,
            onTap: () => setState(() => _mode = PanoramaMode.streetView),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xff10b981)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.white70,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightControlsColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compass Needle
        Tooltip(
          message: 'Бастапқы бағытқа бұру',
          child: GlassContainer(
            dark: true,
            solid: widget.solid,
            radius: 20,
            padding: EdgeInsets.zero,
            onTap: _resetCamera,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Transform.rotate(
                  angle: (_yaw % 1.0) * 2 * math.pi,
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
              _scale = (_scale + 0.4).clamp(1.0, 3.5);
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
              _scale = (_scale - 0.4).clamp(1.0, 3.5);
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

        const SizedBox(height: 8),

        // Open in Google Maps Street View directly
        Tooltip(
          message: 'Google Maps-те қарау',
          child: GlassContainer(
            dark: true,
            solid: widget.solid,
            radius: 18,
            padding: EdgeInsets.zero,
            onTap: _openGoogleMapsExternal,
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: Icon(Icons.open_in_new, size: 16, color: Color(0xff34d399)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: const Color(0xff121c18),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff34d399)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '360° Панорама дайындалуда...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Continuous Equirectangular 360-Degree Cylindrical Wrap Painter
class _EquirectangularPainter extends CustomPainter {
  _EquirectangularPainter({
    required this.image,
    required this.yaw,
    required this.pitch,
    required this.zoom,
  });

  final ui.Image image;
  final double yaw; // 0.0 to 1.0 (continuous circular rotation)
  final double pitch; // -0.35 to 0.35 (vertical angle)
  final double zoom; // 1.0 to 3.5

  @override
  void paint(Canvas canvas, Size size) {
    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();

    final aspect = size.width / size.height;
    final fovW = (imgW / (zoom * aspect * 0.5)).clamp(100.0, imgW);
    final fovH = (imgH / zoom).clamp(100.0, imgH);

    final centerY = (imgH / 2) + (pitch * imgH);
    final top = (centerY - (fovH / 2)).clamp(0.0, imgH - fovH);

    final centerX = (yaw % 1.0) * imgW;
    final left = centerX - (fovW / 2);

    final destRect = Offset.zero & size;
    final paint = Paint()..filterQuality = FilterQuality.medium;

    if (left >= 0 && left + fovW <= imgW) {
      // Direct slice fits in single image buffer
      final srcRect = Rect.fromLTWH(left, top, fovW, fovH);
      canvas.drawImageRect(image, srcRect, destRect, paint);
    } else if (left < 0) {
      // Seamless wrap across left boundary
      final leftWrapW = -left;
      final splitX = (leftWrapW / fovW) * size.width;

      final src1 = Rect.fromLTWH(imgW + left, top, leftWrapW, fovH);
      final dest1 = Rect.fromLTWH(0, 0, splitX, size.height);
      canvas.drawImageRect(image, src1, dest1, paint);

      final rightWrapW = fovW - leftWrapW;
      final src2 = Rect.fromLTWH(0, top, rightWrapW, fovH);
      final dest2 = Rect.fromLTWH(splitX, 0, size.width - splitX, size.height);
      canvas.drawImageRect(image, src2, dest2, paint);
    } else {
      // Seamless wrap across right boundary
      final rightWrapW = imgW - left;
      final splitX = (rightWrapW / fovW) * size.width;

      final src1 = Rect.fromLTWH(left, top, rightWrapW, fovH);
      final dest1 = Rect.fromLTWH(0, 0, splitX, size.height);
      canvas.drawImageRect(image, src1, dest1, paint);

      final nextWrapW = fovW - rightWrapW;
      final src2 = Rect.fromLTWH(0, top, nextWrapW, fovH);
      final dest2 = Rect.fromLTWH(splitX, 0, size.width - splitX, size.height);
      canvas.drawImageRect(image, src2, dest2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EquirectangularPainter old) =>
      old.image != image ||
      old.yaw != yaw ||
      old.pitch != pitch ||
      old.zoom != zoom;
}
