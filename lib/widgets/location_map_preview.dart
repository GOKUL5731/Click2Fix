import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  bool get _supportsGoogleMap {
    if (kIsWeb) {
      return true;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    final markerPosition = LatLng(latitude, longitude);

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
                height: 220,
                child: _supportsGoogleMap
                    ? GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: markerPosition,
                          zoom: 14,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('current-location'),
                            position: markerPosition,
                            infoWindow: const InfoWindow(
                              title: 'Current location',
                            ),
                          ),
                        },
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: false,
                      )
                    : Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Google Maps preview is available on Android, iOS, and Web.',
                            textAlign: TextAlign.center,
                          ),
                        ),
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
