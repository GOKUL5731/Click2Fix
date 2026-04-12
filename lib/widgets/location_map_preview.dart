import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/app_config.dart';
import '../config/app_theme.dart';

/// Location map preview: uses Google Maps on mobile when [AppConfig.googleMapsApiKey] is set
/// (also add the key to AndroidManifest meta-data — see project README / deployment notes).
/// Falls back to a lightweight preview on web or when no key is configured.
class LocationMapPreview extends StatelessWidget {
  const LocationMapPreview({
    super.key,
    this.title = 'Live Area Preview',
    this.latitude = 12.9716,
    this.longitude = 77.5946,
    this.note,
    this.markers,
  });

  final String title;
  final double latitude;
  final double longitude;
  final String? note;
  final Set<Marker>? markers;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final useGoogleMap =
        !kIsWeb && AppConfig.googleMapsApiKey.trim().isNotEmpty;

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
              child: SizedBox(
                height: 180,
                child: useGoogleMap
                    ? GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(latitude, longitude),
                          zoom: 14,
                        ),
                        markers: markers ??
                            {
                              Marker(
                                markerId: const MarkerId('center'),
                                position: LatLng(latitude, longitude),
                              ),
                            },
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        compassEnabled: false,
                        mapToolbarEnabled: false,
                      )
                    : _MapPlaceholder(cs: cs, latitude: latitude, longitude: longitude),
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

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({
    required this.cs,
    required this.latitude,
    required this.longitude,
  });

  final ColorScheme cs;
  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _MapGridPainter(cs)),
          ),
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
