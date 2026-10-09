import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_route/app.dart';
import 'package:local_route/routing/models/routing_failure.dart';
import 'package:local_route/routing/repository/routing_repository.dart';
import 'support/routing_fakes.dart';

class _LocalTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
}

void main() {
  Future<void> selectEndpoints(WidgetTester tester) async {
    final center = tester.getCenter(find.byType(FlutterMap));
    await tester.longPressAt(center - const Offset(50, 0));
    await tester.pumpAndSettle();
    await tester.longPressAt(center + const Offset(50, 0));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'endpoint selection, loading, geometry, metrics, edit and reset',
    (tester) async {
      final service = ControlledService();
      await tester.pumpWidget(
        LocalRouteApp(
          tileProvider: _LocalTiles(),
          repository: RoutingRepository(service: service),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await selectEndpoints(tester);
      expect(find.text('A Origin ✓'), findsOneWidget);
      expect(find.text('B Destination ✓'), findsOneWidget);
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length,
        2,
      );
      expect(service.pending, isEmpty);
      await tester.tap(find.text('Get Route'));
      await tester.pump();
      expect(find.text('Finding a driving route…'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      service.pending.single.complete(exampleRoute());
      await tester.pumpAndSettle();
      expect(find.text('2.5 km · 8 min estimated'), findsOneWidget);
      final polyline = tester
          .widget<PolylineLayer>(find.byType(PolylineLayer))
          .polylines
          .single;
      expect(polyline.points.length, 3);
      expect(polyline.points[1].longitude, 67.015);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      expect(find.text('Powered by GraphHopper API'), findsOneWidget);
      await tester.tap(find.text('A Origin ✓'));
      await tester.pumpAndSettle();
      await tester.longPressAt(tester.getCenter(find.byType(FlutterMap)));
      await tester.pumpAndSettle();
      expect(find.byType(PolylineLayer), findsNothing);
      expect(find.byKey(const Key('route-summary')), findsNothing);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
        isEmpty,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('friendly failure, explicit retry and reset during loading', (
    tester,
  ) async {
    final service = ControlledService();
    await tester.pumpWidget(
      LocalRouteApp(
        tileProvider: _LocalTiles(),
        repository: RoutingRepository(service: service),
      ),
    );
    await tester.pumpAndSettle();
    await selectEndpoints(tester);
    await tester.tap(find.text('Get Route'));
    await tester.pump();
    service.pending.single.completeError(RoutingFailure.network);
    await tester.pumpAndSettle();
    expect(find.text(RoutingFailure.network.message), findsOneWidget);
    expect(find.byType(PolylineLayer), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(service.pending.length, 2);
    expect(find.byKey(const Key('routing-error')), findsNothing);
    await tester.tap(find.text('Reset'));
    await tester.pump();
    service.pending.last.complete(exampleRoute());
    await tester.pumpAndSettle();
    expect(find.byType(PolylineLayer), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('small landscape remains usable with scrolling controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(LocalRouteApp(tileProvider: _LocalTiles()));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(FlutterMap)).height, greaterThan(50));
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Map launches with attribution and supports zoom and pan', (
    tester,
  ) async {
    await tester.pumpWidget(LocalRouteApp(tileProvider: _LocalTiles()));
    await tester.pumpAndSettle();

    expect(find.text('Local Route'), findsOneWidget);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final controller = map.mapController!;
    expect(controller.camera.zoom, 12);

    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();
    expect(controller.camera.zoom, 13);
    await tester.tap(find.byTooltip('Zoom out'));
    await tester.pumpAndSettle();
    expect(controller.camera.zoom, 12);

    await tester.pump(const Duration(seconds: 1));
    final originalCenter = controller.camera.center;
    final originalZoom = controller.camera.zoom;
    await tester.drag(find.byType(FlutterMap), const Offset(100, 60));
    await tester.pumpAndSettle();
    expect(controller.camera.center, isNot(originalCenter));
    expect(controller.camera.zoom, originalZoom);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets('quick tap-and-drag does not zoom with ${kind.name}', (
      tester,
    ) async {
      await tester.pumpWidget(LocalRouteApp(tileProvider: _LocalTiles()));
      await tester.pumpAndSettle();
      final mapFinder = find.byType(FlutterMap);
      final controller = tester.widget<FlutterMap>(mapFinder).mapController!;
      final position = tester.getCenter(mapFinder);
      final originalZoom = controller.camera.zoom;

      // Start the second contact inside flutter_map's double-tap window.
      final tap = await tester.startGesture(position, kind: kind);
      await tester.pump(const Duration(milliseconds: 30));
      await tap.up();
      await tester.pump(const Duration(milliseconds: 50));
      final drag = await tester.startGesture(position, kind: kind);
      await drag.moveBy(const Offset(0, 30));
      await tester.pump(const Duration(milliseconds: 16));
      await drag.moveBy(const Offset(0, 60));
      await tester.pump(const Duration(milliseconds: 16));
      expect(controller.camera.zoom, originalZoom);
      await drag.moveBy(const Offset(0, -120));
      await tester.pump(const Duration(milliseconds: 16));
      expect(controller.camera.zoom, originalZoom);
      await drag.up();
      await tester.pumpAndSettle();
      expect(controller.camera.zoom, originalZoom);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
