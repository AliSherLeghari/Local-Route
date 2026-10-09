import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/route_point.dart';
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

  LatLng _latLng(RoutePoint point) => LatLng(point.latitude, point.longitude);

  void _zoom(double change) {
    final camera = _mapController.camera;
    _mapController.move(camera.center, (camera.zoom + change).clamp(3.0, 19.0));
  }

  Future<void> _openLink(String url, String fallback) async {
    try {
      if (await launchUrl(Uri.parse(url))) return;
    } catch (_) {
      // An unavailable browser should not interrupt map interaction.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(fallback)));
  }

  Marker _marker(RoutePoint point, String label, Color color) => Marker(
    point: _latLng(point),
    width: 44,
    height: 44,
    child: Semantics(
      label: label == 'A' ? 'Origin marker' : 'Destination marker',
      child: CircleAvatar(
        backgroundColor: color,
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    ),
  );

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutingCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Local Route')),
      body: SafeArea(
        child: BlocConsumer<RoutingCubit, RoutingState>(
          listenWhen: (previous, current) =>
              current.isMapReady &&
              current.route != null &&
              previous.route != current.route,
          listener: (context, state) {
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(
                  state.route!.geometry.map(_latLng).toList(),
                ),
                padding: const EdgeInsets.all(40),
                maxZoom: 16,
              ),
            );
          },
          builder: (context, state) => LayoutBuilder(
            builder: (context, constraints) => Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(24.8607, 67.0011),
                      initialZoom: 12,
                      minZoom: 3,
                      maxZoom: 19,
                      interactionOptions: const InteractionOptions(
                        flags:
                            InteractiveFlag.all &
                            ~InteractiveFlag.rotate &
                            ~InteractiveFlag.doubleTapDragZoom,
                      ),
                      onMapReady: cubit.markMapReady,
                      onLongPress: (_, point) =>
                          cubit.selectPosition(point.latitude, point.longitude),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.local_route',
                        maxNativeZoom: 19,
                        tileProvider: widget.tileProvider,
                      ),
                      if (state.route != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: state.route!.geometry
                                  .map(_latLng)
                                  .toList(),
                              strokeWidth: 5,
                              color: Colors.blue.shade800,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          if (state.origin != null)
                            _marker(state.origin!, 'A', Colors.teal.shade800),
                          if (state.destination != null)
                            _marker(
                              state.destination!,
                              'B',
                              Colors.deepOrange.shade800,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * .5,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                state.isMapReady
                                    ? 'Long-press to set ${state.selecting == Endpoint.origin ? 'origin (A)' : 'destination (B)'}. Drag to pan.'
                                    : 'Starting map…',
                              ),
                            ),
                            IconButton(
                              tooltip: 'Zoom out',
                              onPressed: state.isMapReady
                                  ? () => _zoom(-1)
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            IconButton(
                              tooltip: 'Zoom in',
                              onPressed: state.isMapReady
                                  ? () => _zoom(1)
                                  : null,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ChoiceChip(
                              label: Text(
                                'A Origin${state.origin == null ? '' : ' ✓'}',
                              ),
                              selected: state.selecting == Endpoint.origin,
                              onSelected: (_) =>
                                  cubit.selectEndpoint(Endpoint.origin),
                            ),
                            ChoiceChip(
                              label: Text(
                                'B Destination${state.destination == null ? '' : ' ✓'}',
                              ),
                              selected: state.selecting == Endpoint.destination,
                              onSelected: (_) =>
                                  cubit.selectEndpoint(Endpoint.destination),
                            ),
                            TextButton(
                              onPressed: cubit.reset,
                              child: const Text('Reset'),
                            ),
                            FilledButton(
                              onPressed: state.canRequest
                                  ? cubit.requestRoute
                                  : null,
                              child: Text(
                                state.failure == null
                                    ? 'Get Route'
                                    : 'Try again',
                              ),
                            ),
                          ],
                        ),
                        if (state.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Finding a driving route…'),
                              ],
                            ),
                          ),
                        if (state.failure != null)
                          Text(
                            state.failure!.message,
                            key: const Key('routing-error'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        if (state.route != null)
                          Text(
                            '${(state.route!.distanceMeters / 1000).toStringAsFixed(1)} km · '
                            '${(state.route!.duration.inMilliseconds / 60000).ceil()} min estimated',
                            key: const Key('route-summary'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        const Text(
                          'Get Route sends both points to GraphHopper. No live traffic.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _openLink(
                        'https://www.openstreetmap.org/copyright',
                        'Visit openstreetmap.org/copyright for map credits.',
                      ),
                      child: const Text('© OpenStreetMap contributors'),
                    ),
                    TextButton(
                      onPressed: () => _openLink(
                        'https://www.graphhopper.com/',
                        'Visit graphhopper.com for routing credits.',
                      ),
                      child: const Text('Powered by GraphHopper API'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
