import 'package:flutter_test/flutter_test.dart';
import 'package:local_route/routing/models/route_result.dart';
import 'package:local_route/routing/models/routing_limits.dart';
import 'package:local_route/routing/presentation/cubit/routing_state.dart';
import 'support/routing_fakes.dart';

void main() {
  test('state copies waypoint lists and enforces maximum', () {
    final points = [origin];
    final state = RoutingState(waypoints: points);
    points.clear();
    expect(state.waypoints, [origin]);
    expect(() => state.waypoints.add(destination), throwsUnsupportedError);
    final replacement = [destination];
    final next = state.copyWith(waypoints: replacement);
    replacement.clear();
    expect(next.waypoints, [destination]);
    expect(state.waypoints, [origin]);
    expect(
      () => RoutingState(
        waypoints: List.filled(maxIntermediateWaypoints + 1, origin),
      ),
      throwsArgumentError,
    );
  });
  for (final (distance, micros) in [
    (-0.25, -123),
    (0.25, 123),
    (0.0, 0),
    (-0.25, 123),
    (0.25, -123),
  ]) {
    test('raw comparison distance $distance duration $micros', () {
      final baseline = RouteResult(
        geometry: [origin, destination],
        distanceMeters: 2500.5,
        duration: const Duration(microseconds: 60000001),
      );
      final preferred = RouteResult(
        geometry: [origin, destination],
        distanceMeters: 2500.5 + distance,
        duration: Duration(microseconds: 60000001 + micros),
      );
      final state = RoutingState(
        waypoints: [origin],
        conventionalRoute: baseline,
        preferredRoute: preferred,
      );
      expect(state.distanceDifferenceMeters, distance);
      expect(state.durationDifference, Duration(microseconds: micros));
      expect(
        state.copyWith(preferredRoute: null).distanceDifferenceMeters,
        isNull,
      );
      expect(
        state.copyWith(conventionalRoute: null).durationDifference,
        isNull,
      );
      expect(state.copyWith(waypoints: []).hasComparison, isFalse);
    });
  }
}
