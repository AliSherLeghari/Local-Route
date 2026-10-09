import 'package:flutter_test/flutter_test.dart';
import 'package:local_route/routing/models/route_point.dart';
import 'package:local_route/routing/models/routing_failure.dart';
import 'package:local_route/routing/models/routing_limits.dart';
import 'package:local_route/routing/presentation/cubit/routing_cubit.dart';
import 'package:local_route/routing/presentation/cubit/routing_state.dart';
import 'package:local_route/routing/repository/routing_repository.dart';
import 'support/routing_fakes.dart';

void main() {
  late ControlledService service;
  late RoutingCubit cubit;
  final points = [
    RoutePoint(latitude: 24.89, longitude: 67.04),
    RoutePoint(latitude: 24.85, longitude: 67.02),
    RoutePoint(latitude: 24.87, longitude: 67.05),
  ];
  void endpoints() {
    cubit.selectPosition(origin.latitude, origin.longitude);
    cubit.selectPosition(destination.latitude, destination.longitude);
  }

  Future<void> flush() => Future<void>.delayed(Duration.zero);
  setUp(() {
    service = ControlledService();
    cubit = RoutingCubit(repository: RoutingRepository(service: service));
  });
  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  test(
    'add, select, edit, replace, reorder and remove keep order without requests',
    () {
      endpoints();
      expect(cubit.beginAddWaypoint(), isTrue);
      expect(cubit.state.waypoints, isEmpty);
      cubit.selectPosition(points[0].latitude, points[0].longitude);
      cubit.addWaypoint(points[1]);
      cubit.addWaypoint(points[2]);
      final original = cubit.state.waypoints;
      cubit.selectWaypoint(1);
      cubit.selectPosition(24.91, 67.06);
      expect(
        cubit.state.waypoints[1],
        RoutePoint(latitude: 24.91, longitude: 67.06),
      );
      cubit.replaceWaypoint(1, points[1]);
      cubit.selectWaypoint(0);
      cubit.reorderWaypoint(0, 2);
      expect(cubit.state.waypoints, [points[1], points[2], points[0]]);
      expect(cubit.state.selectedWaypointIndex, isNull);
      cubit.reorderWaypoint(2, 0);
      expect(cubit.state.waypoints, points);
      cubit.selectWaypoint(2);
      cubit.removeWaypoint(1);
      expect(cubit.state.waypoints, [points[0], points[2]]);
      expect(cubit.state.selectedWaypointIndex, isNull);
      expect(original, points);
      expect(() => original.clear(), throwsUnsupportedError);
      expect(cubit.state.origin, origin);
      expect(cubit.state.destination, destination);
      expect(service.pending, isEmpty);
    },
  );

  test(
    'endpoint selection cancels waypoint selection; readiness preserves it',
    () {
      endpoints();
      cubit.addWaypoint(points[0]);
      cubit.selectWaypoint(0);
      cubit.markMapReady();
      expect(cubit.state.selectedWaypointIndex, 0);
      cubit.selectEndpoint(Endpoint.origin);
      cubit.selectPosition(24.9, 67.1);
      expect(cubit.state.waypoints, [points[0]]);
      expect(cubit.state.origin!.latitude, 24.9);
      cubit.beginAddWaypoint();
      cubit.selectEndpoint(Endpoint.destination);
      expect(cubit.state.isAddingWaypoint, isFalse);
    },
  );

  test('limit and invalid indices are safe without requests', () {
    for (final point in points) {
      expect(cubit.addWaypoint(point), isTrue);
    }
    expect(cubit.state.waypoints.length, maxIntermediateWaypoints);
    expect(cubit.addWaypoint(origin), isFalse);
    expect(cubit.beginAddWaypoint(), isFalse);
    expect(cubit.state.inputFailure, RoutingFailure.tooManyWaypoints);
    final before = cubit.state;
    for (final index in [-1, 3, 999]) {
      expect(cubit.selectWaypoint(index), isFalse);
      expect(cubit.replaceWaypoint(index, origin), isFalse);
      expect(cubit.removeWaypoint(index), isFalse);
      expect(cubit.reorderWaypoint(index, 0), isFalse);
      expect(cubit.reorderWaypoint(0, index), isFalse);
      expect(cubit.state, same(before));
    }
    expect(cubit.reorderWaypoint(1, 1), isTrue);
    expect(cubit.state, same(before));
    expect(cubit.state.waypoints, points);
    expect(service.pending, isEmpty);
    cubit.removeWaypoint(0);
    expect(cubit.state.inputFailure, isNull);
    expect(cubit.state.canAddWaypoint, isTrue);
  });

  test('invalid coordinate during waypoint editing preserves valid input', () {
    endpoints();
    cubit.addWaypoint(points[0]);
    cubit.selectWaypoint(0);
    cubit.selectPosition(double.nan, 0);
    expect(cubit.state.waypoints, [points[0]]);
    expect(cubit.state.inputFailure, RoutingFailure.invalidCoordinate);
    expect(service.pending, isEmpty);
  });

  for (final count in [0, 1, 2, 3]) {
    test('$count waypoints submit only required ordered requests', () async {
      endpoints();
      for (final point in points.take(count)) {
        cubit.addWaypoint(point);
      }
      expect(service.pending, isEmpty);
      final request = cubit.requestRoute();
      expect(cubit.state.isConventionalLoading, isTrue);
      expect(cubit.state.isPreferredLoading, count > 0);
      expect(cubit.state.canRequest, isFalse);
      await cubit.requestRoute();
      expect(service.pending.length, count == 0 ? 1 : 2);
      expect(service.waypointRequests.first, isEmpty);
      if (count > 0) expect(service.waypointRequests[1], points.take(count));
      for (final request in service.pending) {
        request.complete(exampleRoute());
      }
      await request;
      expect(cubit.state.hasComparison, count > 0);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.canRequest, isFalse);
      await cubit.requestRoute();
      expect(service.pending.length, count == 0 ? 1 : 2);
    });
  }

  test(
    'waypoint changes reuse baseline and remove-last returns conventional only',
    () async {
      endpoints();
      final initial = cubit.requestRoute();
      final baseline = exampleRoute();
      service.pending[0].complete(baseline);
      await initial;
      cubit.addWaypoint(points[0]);
      final comparison = cubit.requestRoute();
      expect(service.pending.length, 2);
      expect(service.waypointRequests.last, [points[0]]);
      service.pending[1].complete(exampleRoute());
      await comparison;
      cubit.replaceWaypoint(0, points[1]);
      expect(cubit.state.conventionalRoute, same(baseline));
      expect(cubit.state.preferredRoute, isNull);
      expect(cubit.state.distanceDifferenceMeters, isNull);
      expect(service.pending.length, 2);
      cubit.removeWaypoint(0);
      await cubit.requestRoute();
      expect(service.pending.length, 2);
      expect(cubit.state.route, same(baseline));
    },
  );

  for (final failedPreferred in [false, true]) {
    test(
      'partial failure ($failedPreferred) preserves success and retries only failure',
      () async {
        endpoints();
        cubit.addWaypoint(points[0]);
        final initial = cubit.requestRoute();
        final failed = failedPreferred ? 1 : 0;
        final succeeded = 1 - failed;
        final good = exampleRoute();
        service.pending[succeeded].complete(good);
        await flush();
        expect(
          failedPreferred
              ? cubit.state.conventionalRoute
              : cubit.state.preferredRoute,
          same(good),
        );
        expect(
          failedPreferred
              ? cubit.state.isPreferredLoading
              : cubit.state.isConventionalLoading,
          isTrue,
        );
        service.pending[failed].completeError(RoutingFailure.noRoute);
        await initial;
        expect(
          failedPreferred
              ? cubit.state.preferredFailure
              : cubit.state.conventionalFailure,
          RoutingFailure.noRoute,
        );
        expect(cubit.state.hasComparison, isFalse);
        final retry = cubit.requestRoute();
        await cubit.requestRoute();
        expect(service.pending.length, 3);
        expect(
          service.waypointRequests.last,
          failedPreferred ? [points[0]] : isEmpty,
        );
        service.pending[2].complete(exampleRoute());
        await retry;
        expect(cubit.state.hasComparison, isTrue);
        expect(cubit.state.failure, isNull);
      },
    );
  }

  test('both failures sanitized and both missing results retried', () async {
    endpoints();
    cubit.addWaypoint(points[0]);
    final first = cubit.requestRoute();
    service.pending[0].completeError(StateError('sensitive URL'));
    service.pending[1].completeError(StateError('sensitive response'));
    await first;
    expect(cubit.state.conventionalFailure, RoutingFailure.unavailable);
    expect(cubit.state.preferredFailure, RoutingFailure.unavailable);
    final retry = cubit.requestRoute();
    expect(service.pending.length, 4);
    service.pending[2].complete(exampleRoute());
    service.pending[3].complete(exampleRoute());
    await retry;
    expect(cubit.state.hasComparison, isTrue);
  });

  for (final edit in ['add', 'replace', 'remove', 'reorder']) {
    for (final staleError in [false, true]) {
      test(
        '$edit ignores stale preferred ${staleError ? 'failure' : 'success'} and reuses in-flight baseline',
        () async {
          endpoints();
          cubit.addWaypoint(points[0]);
          cubit.addWaypoint(points[1]);
          final old = cubit.requestRoute();
          switch (edit) {
            case 'add':
              cubit.addWaypoint(points[2]);
            case 'replace':
              cubit.replaceWaypoint(0, points[2]);
            case 'remove':
              cubit.removeWaypoint(0);
            case 'reorder':
              cubit.reorderWaypoint(0, 1);
          }
          expect(service.pending.length, 2);
          expect(cubit.state.isConventionalLoading, isTrue);
          expect(cubit.state.isPreferredLoading, isFalse);
          final latest = cubit.requestRoute();
          expect(service.pending.length, 3);
          final newest = exampleRoute();
          service.pending[2].complete(newest);
          await latest;
          if (staleError) {
            service.pending[1].completeError(RoutingFailure.network);
          } else {
            service.pending[1].complete(exampleRoute());
          }
          service.pending[0].complete(exampleRoute());
          await old;
          expect(cubit.state.preferredRoute, same(newest));
          expect(cubit.state.preferredFailure, isNull);
          expect(cubit.state.hasComparison, isTrue);
        },
      );
    }
  }

  for (final change in [
    'origin',
    'destination',
    'reset',
    'close',
    'removeLast',
  ]) {
    for (final staleError in [false, true]) {
      test(
        '$change invalidates outstanding ${staleError ? 'failures' : 'successes'}',
        () async {
          endpoints();
          cubit.markMapReady();
          cubit.addWaypoint(points[0]);
          final old = cubit.requestRoute();
          switch (change) {
            case 'origin':
              cubit.selectEndpoint(Endpoint.origin);
              cubit.selectPosition(24.9, 67.1);
            case 'destination':
              cubit.selectPosition(24.9, 67.1);
            case 'reset':
              cubit.reset();
            case 'close':
              await cubit.close();
            case 'removeLast':
              cubit.removeWaypoint(0);
          }
          final after = cubit.state;
          for (final pending in service.pending) {
            if (staleError) {
              pending.completeError(RoutingFailure.timeout);
            } else {
              pending.complete(exampleRoute());
            }
          }
          await old;
          if (change == 'removeLast') {
            expect(cubit.state.preferredRoute, isNull);
            expect(cubit.state.preferredFailure, isNull);
            expect(cubit.state.isPreferredLoading, isFalse);
            expect(cubit.state.waypoints, isEmpty);
          } else {
            expect(cubit.state, same(after));
          }
          expect(service.pending.length, 2);
          if (change == 'reset') {
            expect(cubit.state.isMapReady, isTrue);
            expect(cubit.state.waypoints, isEmpty);
            expect(cubit.state.isLoading, isFalse);
          }
        },
      );
    }
  }

  test('retry while other branch is pending does not duplicate it', () async {
    endpoints();
    cubit.addWaypoint(points[0]);
    final initial = cubit.requestRoute();
    service.pending[1].completeError(RoutingFailure.network);
    await flush();
    expect(cubit.state.canRequest, isTrue);
    final retry = cubit.requestRoute();
    expect(service.pending.length, 3);
    expect(service.waypointRequests[2], [points[0]]);
    service.pending[2].complete(exampleRoute());
    await retry;
    expect(cubit.state.isConventionalLoading, isTrue);
    expect(cubit.state.isPreferredLoading, isFalse);
    service.pending[0].complete(exampleRoute());
    await initial;
    expect(cubit.state.hasComparison, isTrue);
    expect(cubit.state.failure, isNull);
  });

  test('old comparison cannot overwrite a newer endpoint comparison', () async {
    endpoints();
    cubit.addWaypoint(points[0]);
    final old = cubit.requestRoute();
    cubit.selectPosition(24.9, 67.1);
    final latest = cubit.requestRoute();
    expect(service.pending.length, 4);
    final baseline = exampleRoute();
    final preferred = exampleRoute();
    service.pending[3].complete(preferred);
    service.pending[2].complete(baseline);
    await latest;
    service.pending[0].completeError(RoutingFailure.timeout);
    service.pending[1].complete(exampleRoute());
    await old;
    expect(cubit.state.conventionalRoute, same(baseline));
    expect(cubit.state.preferredRoute, same(preferred));
    expect(cubit.state.failure, isNull);
    expect(cubit.state.destination!.latitude, 24.9);
  });

  test('methods after close make no requests or state changes', () async {
    await cubit.close();
    final before = cubit.state;
    expect(cubit.addWaypoint(origin), isFalse);
    expect(cubit.beginAddWaypoint(), isFalse);
    expect(cubit.selectWaypoint(0), isFalse);
    expect(cubit.replaceWaypoint(0, origin), isFalse);
    expect(cubit.removeWaypoint(0), isFalse);
    expect(cubit.reorderWaypoint(0, 0), isFalse);
    cubit.selectEndpoint(Endpoint.destination);
    cubit.selectPosition(24, 67);
    cubit.markMapReady();
    cubit.reset();
    await cubit.requestRoute();
    expect(cubit.state, same(before));
    expect(service.pending, isEmpty);
  });
}
