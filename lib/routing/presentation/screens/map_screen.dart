import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/route_point.dart';
import '../../models/route_result.dart';
import '../../models/routing_failure.dart';
import '../../models/routing_limits.dart';
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
      container: true,
      excludeSemantics: true,
      label: label == 'A'
          ? 'Origin marker'
          : label == 'B'
          ? 'Destination marker'
          : 'Waypoint $label marker',
      child: CircleAvatar(
        backgroundColor: color,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: FittedBox(
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    ),
  );

  String _target(RoutingState state) {
    if (state.isAddingWaypoint) {
      return 'waypoint W${state.waypoints.length + 1}';
    }
    if (state.selectedWaypointIndex case final int index) {
      return 'waypoint W${index + 1}';
    }
    return state.selecting == Endpoint.origin
        ? 'origin (A)'
        : 'destination (B)';
  }

  Widget _waypoints(RoutingState state, RoutingCubit cubit) => ExpansionTile(
    key: const Key('waypoints-panel'),
    tilePadding: EdgeInsets.zero,
    title: Text(
      'Waypoints (${state.waypoints.length}/$maxIntermediateWaypoints)',
    ),
    children: [
      for (var i = 0; i < state.waypoints.length; i++)
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChoiceChip(
              label: Text('Edit W${i + 1}'),
              selected: state.selectedWaypointIndex == i,
              onSelected: (_) => cubit.selectWaypoint(i),
            ),
            IconButton(
              tooltip: 'Move W${i + 1} up',
              onPressed: i > 0 ? () => cubit.reorderWaypoint(i, i - 1) : null,
              icon: const Icon(Icons.arrow_upward),
            ),
            IconButton(
              tooltip: 'Move W${i + 1} down',
              onPressed: i + 1 < state.waypoints.length
                  ? () => cubit.reorderWaypoint(i, i + 1)
                  : null,
              icon: const Icon(Icons.arrow_downward),
            ),
            IconButton(
              tooltip: 'Remove W${i + 1}',
              onPressed: () => cubit.removeWaypoint(i),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      TextButton.icon(
        key: const Key('add-waypoint'),
        onPressed: state.isMapReady && state.canAddWaypoint
            ? () => cubit.beginAddWaypoint()
            : null,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add waypoint'),
      ),
      const Text(
        'Waypoints guide the route without adding passenger stopping time. '
        'Points may snap to nearby roads.',
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget _result(
    String label,
    Color color,
    RouteResult? route,
    bool loading,
    RoutingFailure? failure,
    String summaryKey,
    String errorKey,
  ) => Column(
    children: [
      if (route != null || loading || failure != null)
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      if (loading)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              Text(
                label == 'Conventional'
                    ? 'Finding a driving route…'
                    : 'Finding route via waypoints…',
              ),
            ],
          ),
        ),
      if (failure != null)
        Semantics(
          liveRegion: true,
          child: Text(
            failure.message,
            key: Key(errorKey),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      if (route != null)
        Text(
          '${(route.distanceMeters / 1000).toStringAsFixed(1)} km · '
          '${(route.duration.inMilliseconds / 60000).ceil()} min estimated',
          key: Key(summaryKey),
          style: Theme.of(context).textTheme.titleMedium,
        ),
    ],
  );

  String _distanceDifference(double meters) {
    if (meters == 0) return 'Same distance';
    final amount = meters.abs() < 100
        ? '<0.1'
        : (meters.abs() / 1000).toStringAsFixed(1);
    return '$amount km ${meters < 0 ? 'shorter' : 'longer'}';
  }

  String _timeDifference(Duration difference) {
    if (difference == Duration.zero) return 'same estimated time';
    final minutes =
        difference.inMicroseconds.abs() / Duration.microsecondsPerMinute;
    final amount = minutes < 1 ? '<1' : minutes.toStringAsFixed(0);
    return '$amount min ${difference.isNegative ? 'faster' : 'slower'} (estimated)';
  }

  void _fitResults(RoutingState state, RoutingCubit cubit) {
    // Fit after layout, once the submitted branches settle. Selection, edits,
    // expansion and gestures do not trigger a fit. Ignore a superseded callback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          cubit.isClosed ||
          cubit.state.isLoading ||
          cubit.state.conventionalRoute != state.conventionalRoute ||
          cubit.state.preferredRoute != state.preferredRoute) {
        return;
      }
      final points = [
        ...?state.conventionalRoute?.geometry,
        ...?state.preferredRoute?.geometry,
      ];
      if (points.isEmpty) return;
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points.map(_latLng).toList()),
          padding: const EdgeInsets.all(40),
          maxZoom: 16,
        ),
      );
    });
  }

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
              !current.isLoading &&
              (current.conventionalRoute != null ||
                  current.preferredRoute != null) &&
              ((previous.isLoading &&
                      previous.origin == current.origin &&
                      previous.destination == current.destination &&
                      listEquals(previous.waypoints, current.waypoints)) ||
                  (current.conventionalRoute != null &&
                      previous.conventionalRoute !=
                          current.conventionalRoute) ||
                  (current.preferredRoute != null &&
                      previous.preferredRoute != current.preferredRoute)),
          listener: (context, state) => _fitResults(state, cubit),
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
                      if (state.conventionalRoute != null ||
                          state.preferredRoute != null)
                        PolylineLayer(
                          polylines: [
                            if (state.conventionalRoute != null)
                              Polyline(
                                points: state.conventionalRoute!.geometry
                                    .map(_latLng)
                                    .toList(),
                                strokeWidth: 7,
                                color: Colors.blue.shade800,
                              ),
                            if (state.preferredRoute != null)
                              Polyline(
                                points: state.preferredRoute!.geometry
                                    .map(_latLng)
                                    .toList(),
                                strokeWidth: 4,
                                color: Colors.deepOrange.shade800,
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
                          for (var i = 0; i < state.waypoints.length; i++)
                            _marker(
                              state.waypoints[i],
                              'W${i + 1}',
                              Colors.purple.shade800,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        constraints.maxHeight *
                        (constraints.maxWidth > constraints.maxHeight
                            ? .4
                            : .5),
                  ),
                  child: SingleChildScrollView(
                    key: const Key('map-controls'),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                state.isMapReady
                                    ? 'Long-press to set ${_target(state)}. Drag to pan.'
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
                              selected:
                                  !state.isAddingWaypoint &&
                                  state.selectedWaypointIndex == null &&
                                  state.selecting == Endpoint.origin,
                              onSelected: (_) =>
                                  cubit.selectEndpoint(Endpoint.origin),
                            ),
                            ChoiceChip(
                              label: Text(
                                'B Destination${state.destination == null ? '' : ' ✓'}',
                              ),
                              selected:
                                  !state.isAddingWaypoint &&
                                  state.selectedWaypointIndex == null &&
                                  state.selecting == Endpoint.destination,
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
                                state.waypoints.isEmpty
                                    ? 'Get Route'
                                    : 'Compare routes',
                              ),
                            ),
                            if (state.conventionalFailure != null ||
                                state.preferredFailure != null)
                              TextButton(
                                onPressed: state.canRequest
                                    ? cubit.requestRoute
                                    : null,
                                child: const Text('Try again'),
                              ),
                          ],
                        ),
                        _waypoints(state, cubit),
                        Text(
                          [
                            'A',
                            for (var i = 0; i < state.waypoints.length; i++)
                              'W${i + 1}',
                            'B',
                          ].join(' → '),
                          key: const Key('waypoint-sequence'),
                        ),
                        if (state.waypoints.isNotEmpty &&
                            state.preferredRoute == null &&
                            !state.isPreferredLoading &&
                            state.preferredFailure == null)
                          const Text(
                            'Via waypoints needs recalculation. Press Compare routes.',
                            key: Key('waypoint-recalculation'),
                          ),
                        if (state.inputFailure != null)
                          Text(
                            state.inputFailure!.message,
                            key: const Key('input-error'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        _result(
                          'Conventional',
                          Colors.blue.shade800,
                          state.conventionalRoute,
                          state.isConventionalLoading,
                          state.conventionalFailure,
                          'route-summary',
                          'routing-error',
                        ),
                        if (state.waypoints.isNotEmpty)
                          _result(
                            'Via waypoints',
                            Colors.deepOrange.shade800,
                            state.preferredRoute,
                            state.isPreferredLoading,
                            state.preferredFailure,
                            'preferred-summary',
                            'preferred-error',
                          ),
                        if (state.hasComparison)
                          Text(
                            'Via waypoints: ${_distanceDifference(state.distanceDifferenceMeters!)} · '
                            '${_timeDifference(state.durationDifference!)}',
                            key: const Key('route-differences'),
                          ),
                        const Text(
                          'Submitting sends selected coordinates to GraphHopper. No live traffic.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth,
                        ),
                        child: TextButton(
                          onPressed: () => _openLink(
                            'https://www.openstreetmap.org/copyright',
                            'Visit openstreetmap.org/copyright for map credits.',
                          ),
                          child: const Text('© OpenStreetMap contributors'),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth,
                        ),
                        child: TextButton(
                          onPressed: () => _openLink(
                            'https://www.graphhopper.com/',
                            'Visit graphhopper.com for routing credits.',
                          ),
                          child: const Text('Powered by GraphHopper API'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
