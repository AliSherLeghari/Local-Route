import 'package:flutter_test/flutter_test.dart';
import 'package:local_route/routing/models/routing_failure.dart';
import 'package:local_route/routing/repository/routing_repository.dart';
import 'support/routing_fakes.dart';

void main() {
  test(
    'repository passes endpoints and neutral result without conversion',
    () async {
      final service = ControlledService();
      final repository = RoutingRepository(service: service);
      final future = repository.route(origin, destination);
      expect(service.endpoints.single, (origin, destination));
      final result = exampleRoute();
      service.pending.single.complete(result);
      expect(await future, same(result));
    },
  );
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
