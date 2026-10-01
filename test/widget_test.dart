import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_route/app.dart';

class _LocalTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
}

void main() {
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

    final originalCenter = controller.camera.center;
    await tester.drag(find.byType(FlutterMap), const Offset(100, 60));
    await tester.pumpAndSettle();
    expect(controller.camera.center, isNot(originalCenter));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
