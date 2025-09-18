import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/services/location_service.dart';
import '../../state/providers.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final _locationService = const LocationService();
  LatLng _initialPosition = const LatLng(41.015137, 28.97953);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final position = await _locationService.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      if (position != null) {
        _initialPosition = LatLng(position.latitude, position.longitude);
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessesAsync = ref.watch(exploreProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Size En Yakın Berberler')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : businessesAsync.when(
              data: (businesses) {
                final markers = businesses
                    .where((b) => b.latitude != null && b.longitude != null)
                    .map(
                      (b) => Marker(
                        markerId: MarkerId(b.id),
                        position: LatLng(b.latitude!, b.longitude!),
                        infoWindow: InfoWindow(title: b.name, snippet: b.address),
                      ),
                    )
                    .toSet();
                return GoogleMap(
                  initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 12),
                  markers: markers,
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Harita yüklenemedi: $error')),
            ),
    );
  }
}
