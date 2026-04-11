import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Location map preview widget.
/// Shows a styled static preview card with coordinates.
/// To enable live Google Maps: add google_maps_flutter to pubspec.yaml
/// and set the API key via --dart-define=GOOGLE_MAPS_API_KEY=...
class LocationMapPreview extends StatelessWidget {
  const LocationMapPreview({
    super.key,
    this.title = 'Live Area Preview',
    this.latitude = 12.9716,
    this.longitude = 77.5946,
    this.note,
  });

  final String title;
  final double latitude;
  final double longitude;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 180,
                color: cs.surfaceContainerHighest,
                child: Stack(
                  children: [
                    // Map placeholder grid pattern
                    Positioned.fill(
                      child: CustomPaint(painter: _MapGridPainter(cs)),
                    ),
                    // Center pin
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withAlpha(80),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.location_on, color: Colors.white, size: 24),
                          ),
                          Container(
                            width: 2,
                            height: 8,
                            color: AppColors.primaryBlue,
                          ),
                        ],
                      ),
                    ),
                    // Coordinates badge
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(160),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (note != null) ...[
              const SizedBox(height: 10),
              Text(note!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter(this.cs);
  final ColorScheme cs;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cs.onSurface.withAlpha(15)
      ..strokeWidth = 1;
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter old) => false;
}

