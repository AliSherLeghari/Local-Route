import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:local_route/routing/models/route_point.dart';
import 'package:local_route/routing/models/routing_failure.dart';
import 'package:local_route/routing/models/routing_limits.dart';
import 'package:local_route/routing/repository/routing_repository.dart';
import 'package:local_route/routing/services/routing_service.dart';
import 'support/routing_fakes.dart';

void main() {
  test(
    'repository passes endpoints and neutral result without conversion',
    () async {
      final service = ControlledService();
      final repository = RoutingRepository(service: service);
      final future = repository.route(origin, destination);
      expect(service.endpoints.single, (origin, destination));
      expect(service.waypointRequests.single, isEmpty);
      final result = exampleRoute();
      service.pending.single.complete(result);
      expect(await future, same(result));
    },
  );
  for (final count in [0, 1, 2, 3]) {
    test('repository forwards $count waypoints in order', () async {
      final service = ControlledService();
      final selected = [
        RoutePoint(latitude: 24.89, longitude: 67.04),
        RoutePoint(latitude: 24.85, longitude: 67.02),
        RoutePoint(latitude: 24.87, longitude: 67.05),
      ].take(count).toList();
      final future = RoutingRepository(
        service: service,
      ).route(origin, destination, waypoints: selected);
      expect(service.endpoints.single, (origin, destination));
      expect(service.waypointRequests.single, selected);
      final result = exampleRoute();
      service.pending.single.complete(result);
      expect(await future, same(result));
    });
  }
  test('repository propagates waypoint limit failure without HTTP', () async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response('{}', 200);
    });
    addTearDown(client.close);
    final repository = RoutingRepository(
      service: RoutingService(client: client, apiKey: 'test-only-placeholder'),
    );
    await expectLater(
      repository.route(
        origin,
        destination,
        waypoints: List.filled(maxIntermediateWaypoints + 1, origin),
      ),
      throwsA(RoutingFailure.tooManyWaypoints),
    );
    expect(requests, 0);
  });
  test('repository preserves safe failure', () async {
    final service = ControlledService();
    final future = RoutingRepository(
      service: service,
    ).route(origin, destination);
    final expectation = expectLater(future, throwsA(RoutingFailure.noRoute));
    service.pending.single.completeError(RoutingFailure.noRoute);
    await expectation;
  });
}
