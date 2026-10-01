import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../cubit/routing_cubit.dart';
import '../cubit/routing_state.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.tileProvider});

  final TileProvider? tileProvider;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();

  void _zoom(double change) {
    final camera = _mapController.camera;
    _mapController.move(camera.center, (camera.zoom + change).clamp(3.0, 19.0));
  }

  Future<void> _openAttribution() async {
    try {
      if (await launchUrl(
        Uri.parse('https://www.openstreetmap.org/copyright'),
      )) {
        return;
      }
    } catch (_) {
      // An unavailable browser should not interrupt map interaction.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Visit openstreetmap.org/copyright for map credits.'),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local Route')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  // A starting view of Karachi, not the user's GPS position.
                  initialCenter: const LatLng(24.8607, 67.0011),
                  initialZoom: 12,
                  minZoom: 3,
                  maxZoom: 19,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onMapReady: context.read<RoutingCubit>().markMapReady,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.local_route',
                    maxNativeZoom: 19,
                    tileProvider: widget.tileProvider,
                    // Keep flutter_map's default HTTP-aware tile caching.
                  ),
                ],
              ),
            ),
            BlocBuilder<RoutingCubit, RoutingState>(
              builder: (context, state) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.isMapReady
                            ? 'Drag to pan. Pinch to zoom.\nInternet needed for new map tiles.'
                            : 'Starting map…',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Zoom out',
                      onPressed: state.isMapReady ? () => _zoom(-1) : null,
                      icon: const Icon(Icons.remove),
                    ),
                    IconButton(
                      tooltip: 'Zoom in',
                      onPressed: state.isMapReady ? () => _zoom(1) : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: _openAttribution,
              child: const Text('© OpenStreetMap contributors'),
            ),
          ],
        ),
      ),
    );
  }
}
