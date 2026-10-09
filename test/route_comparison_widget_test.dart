import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_route/app.dart';
import 'package:local_route/routing/models/route_point.dart';
import 'package:local_route/routing/models/route_result.dart';
import 'package:local_route/routing/models/routing_failure.dart';
import 'package:local_route/routing/presentation/cubit/routing_cubit.dart';
import 'package:local_route/routing/presentation/screens/map_screen.dart';
import 'package:local_route/routing/repository/routing_repository.dart';
import 'support/routing_fakes.dart';

class _LocalTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
}

void main() {
  late ControlledService service;
  Future<void> start(WidgetTester tester, {double textScale = 1}) async {
    service = ControlledService();
    if (textScale == 1) {
      await tester.pumpWidget(
        LocalRouteApp(
          tileProvider: _LocalTiles(),
          repository: RoutingRepository(service: service),
        ),
      );
    } else {
      await tester.pumpWidget(
        BlocProvider(
          create: (_) =>
              RoutingCubit(repository: RoutingRepository(service: service)),
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: MapScreen(tileProvider: _LocalTiles()),
          ),
        ),
      );
    }
    await tester.pumpAndSettle();
    final center = tester.getCenter(find.byType(FlutterMap));
    await tester.longPressAt(center - const Offset(45, 0));
    await tester.pumpAndSettle();
    await tester.longPressAt(center + const Offset(45, 0));
    await tester.pumpAndSettle();
  }

  RoutingCubit cubit(WidgetTester tester) =>
      tester.element(find.byType(MapScreen)).read<RoutingCubit>();
  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    // Fixed pumps allow controls to be exercised with requests still pending.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> expand(WidgetTester tester) =>
      tap(tester, find.byKey(const Key('waypoints-panel')));
  Future<void> add(WidgetTester tester, int index) async {
    await tap(tester, find.text('Add waypoint'));
    await tester.longPressAt(
      tester.getCenter(find.byType(FlutterMap)) + Offset(index * 20 - 20, 10),
    );
    await tester.pump();
  }

  RouteResult preferred({double meters = 2000, int minutes = 10}) =>
      RouteResult(
        geometry: [
          origin,
          RoutePoint(latitude: 24.94, longitude: 67.12),
          destination,
        ],
        distanceMeters: meters,
        duration: Duration(minutes: minutes),
      );
  Future<void> submit(WidgetTester tester) =>
      tap(tester, find.text('Compare routes'));

  testWidgets(
    'waypoints add/edit/reorder/remove and enforce max without requests',
    (tester) async {
      await start(tester);
      final semantics = tester.ensureSemantics();
      await expand(tester);
      for (var i = 0; i < 3; i++) {
        await add(tester, i);
      }
      final selected = cubit(tester).state.waypoints;
      expect(find.text('Waypoints (3/3)'), findsOneWidget);
      expect(find.text('A → W1 → W2 → W3 → B'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('add-waypoint')))
            .onPressed,
        isNull,
      );
      final markers = tester
          .widget<MarkerLayer>(find.byType(MarkerLayer))
          .markers;
      expect(markers.length, 5);
      for (final label in ['A', 'B', 'W1', 'W2', 'W3']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.bySemanticsLabel('Waypoint W1 marker'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byTooltip('Move W1 up'),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byTooltip('Move W3 down'),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );
      await tap(tester, find.byTooltip('Move W1 down'));
      expect(cubit(tester).state.waypoints, [
        selected[1],
        selected[0],
        selected[2],
      ]);
      await tap(tester, find.byTooltip('Move W2 up'));
      expect(cubit(tester).state.waypoints, selected);
      await tap(tester, find.text('Edit W2'));
      expect(
        find.text('Long-press to set waypoint W2. Drag to pan.'),
        findsOneWidget,
      );
      await tester.longPressAt(
        tester.getCenter(find.byType(FlutterMap)) + const Offset(60, 30),
      );
      await tester.pump();
      expect(cubit(tester).state.waypoints[1], isNot(selected[1]));
      expect(cubit(tester).state.waypoints[0], selected[0]);
      await tap(tester, find.byTooltip('Remove W2'));
      expect(cubit(tester).state.waypoints, [selected[0], selected[2]]);
      expect(find.text('A → W1 → W2 → B'), findsOneWidget);
      expect(service.pending, isEmpty);
      await tap(tester, find.text('Reset'));
      expect(find.text('Waypoints (0/3)'), findsOneWidget);
      expect(find.text('Get Route'), findsOneWidget);
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'two polylines, raw differences, combined camera and no refit on edits',
    (tester) async {
      await start(tester);
      await expand(tester);
      await add(tester, 0);
      await submit(tester);
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      final controller = map.mapController!;
      final zoomBefore = controller.camera.zoom;
      service.pending[0].complete(exampleRoute());
      await tester.pump();
      expect(controller.camera.zoom, zoomBefore);
      final via = preferred();
      service.pending[1].complete(via);
      await tester.pumpAndSettle();
      final lines = tester
          .widget<PolylineLayer>(find.byType(PolylineLayer))
          .polylines;
      expect(lines.length, 2);
      expect(lines[0].color, isNot(lines[1].color));
      expect(lines[0].strokeWidth, greaterThan(lines[1].strokeWidth));
      expect(lines[1].points.length, via.geometry.length);
      expect(find.text('Conventional'), findsOneWidget);
      expect(find.text('Via waypoints'), findsOneWidget);
      expect(find.text('2.5 km · 8 min estimated'), findsOneWidget);
      expect(find.text('2.0 km · 10 min estimated'), findsOneWidget);
      expect(
        find.text('Via waypoints: 0.5 km shorter · 2 min slower (estimated)'),
        findsOneWidget,
      );
      for (final line in lines) {
        for (final point in line.points) {
          expect(controller.camera.visibleBounds.contains(point), isTrue);
        }
      }
      await tester.pump(const Duration(seconds: 1));
      await tester.drag(find.byType(FlutterMap), const Offset(50, 20));
      await tester.pumpAndSettle();
      final center = controller.camera.center;
      final zoom = controller.camera.zoom;
      await tap(tester, find.text('Edit W1'));
      expect(controller.camera.center, center);
      expect(controller.camera.zoom, zoom);
      await tester.longPressAt(tester.getCenter(find.byType(FlutterMap)));
      await tester.pumpAndSettle();
      expect(controller.camera.center, center);
      expect(controller.camera.zoom, zoom);
      expect(find.byKey(const Key('route-summary')), findsOneWidget);
      expect(find.byKey(const Key('preferred-summary')), findsNothing);
      expect(find.byKey(const Key('waypoint-recalculation')), findsOneWidget);
      expect(find.byKey(const Key('route-differences')), findsNothing);
      expect(service.pending.length, 2);
      await submit(tester);
      expect(service.pending.length, 3);
      // Removing a waypoint while loading must not refit the retained baseline.
      await tap(tester, find.byTooltip('Remove W1'));
      expect(controller.camera.center, center);
      expect(controller.camera.zoom, zoom);
      service.pending[2].complete(preferred());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('preferred-summary')), findsNothing);
      expect(controller.camera.center, center);
      expect(service.pending.length, 3);
      expect(tester.takeException(), isNull);
    },
  );

  for (final failedPreferred in [true, false]) {
    testWidgets(
      'partial failure $failedPreferred keeps success and retries only failure',
      (tester) async {
        await start(tester);
        await expand(tester);
        await add(tester, 0);
        await submit(tester);
        service.pending[failedPreferred ? 0 : 1].complete(exampleRoute());
        service.pending[failedPreferred ? 1 : 0].completeError(
          RoutingFailure.network,
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            Key(failedPreferred ? 'route-summary' : 'preferred-summary'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            Key(failedPreferred ? 'preferred-error' : 'routing-error'),
          ),
          findsOneWidget,
        );
        expect(
          tester
              .widget<PolylineLayer>(find.byType(PolylineLayer))
              .polylines
              .length,
          1,
        );
        expect(find.byKey(const Key('route-differences')), findsNothing);
        await tap(tester, find.text('Try again'));
        expect(service.pending.length, 3);
        expect(service.waypointRequests.last.isNotEmpty, failedPreferred);
        service.pending[2].complete(exampleRoute());
        await tester.pumpAndSettle();
        expect(
          find.text('Via waypoints: Same distance · same estimated time'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('preferred-error')), findsNothing);
        expect(find.byKey(const Key('routing-error')), findsNothing);
      },
    );
  }

  testWidgets(
    'reset ignores pending comparison completions and does not fit camera',
    (tester) async {
      await start(tester);
      await expand(tester);
      await add(tester, 0);
      await submit(tester);
      await tap(tester, find.text('Reset'));
      final controller = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .mapController!;
      final zoom = controller.camera.zoom;
      final center = controller.camera.center;
      service.pending[0].complete(exampleRoute());
      service.pending[1].completeError(RoutingFailure.noRoute);
      await tester.pumpAndSettle();
      expect(find.byType(PolylineLayer), findsNothing);
      expect(find.byKey(const Key('preferred-error')), findsNothing);
      expect(controller.camera.zoom, zoom);
      expect(controller.camera.center, center);
    },
  );

  for (final (meters, minutes, expected) in [
    (3000.0, 6, '0.5 km longer · 2 min faster (estimated)'),
    (2499.9, 8, '<0.1 km shorter · same estimated time'),
  ]) {
    testWidgets('comparison formats $expected', (tester) async {
      await start(tester);
      await expand(tester);
      await add(tester, 0);
      await submit(tester);
      service.pending[0].complete(exampleRoute());
      service.pending[1].complete(preferred(meters: meters, minutes: minutes));
      await tester.pumpAndSettle();
      expect(find.text('Via waypoints: $expected'), findsOneWidget);
    });
  }

  for (final (size, scale) in [
    (const Size(320, 640), 1.0),
    (const Size(640, 360), 1.0),
    (const Size(320, 640), 2.0),
    (const Size(640, 360), 2.0),
  ]) {
    testWidgets('all waypoint controls reachable at $size text $scale', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await start(tester, textScale: scale);
      await expand(tester);
      for (var i = 0; i < 3; i++) {
        await add(tester, i);
      }
      await tap(tester, find.byTooltip('Move W3 up'));
      expect(
        find.text('© OpenStreetMap contributors').hitTestable(),
        findsOneWidget,
      );
      await submit(tester);
      service.pending[0].complete(exampleRoute());
      service.pending[1].complete(preferred());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('route-differences')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('route-differences')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.getSize(find.byType(FlutterMap)).height, greaterThan(80));
      await tap(tester, find.byTooltip('Remove W3'));
      expect(find.text('Waypoints (2/3)'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(service.pending.length, 2);
    });
  }

  testWidgets(
    'reorder during loading ignores old route and keeps camera stable',
    (tester) async {
      await start(tester);
      await expand(tester);
      await add(tester, 0);
      await add(tester, 1);
      await submit(tester);
      service.pending[0].complete(exampleRoute());
      await tester.pump();
      final controller = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .mapController!;
      final center = controller.camera.center;
      final zoom = controller.camera.zoom;
      await tap(tester, find.byTooltip('Move W2 up'));
      expect(controller.camera.center, center);
      expect(controller.camera.zoom, zoom);
      expect(service.pending.length, 2);
      service.pending[1].complete(preferred());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('preferred-summary')), findsNothing);
      expect(find.byKey(const Key('route-summary')), findsOneWidget);
      expect(find.byKey(const Key('waypoint-recalculation')), findsOneWidget);
      await submit(tester);
      expect(service.pending.length, 3);
      expect(service.waypointRequests.last, cubit(tester).state.waypoints);
      service.pending[2].complete(preferred());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('preferred-summary')), findsOneWidget);
    },
  );
}
