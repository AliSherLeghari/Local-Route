import 'package:flutter_test/flutter_test.dart';
import 'package:local_route/routing/models/routing_failure.dart';
import 'package:local_route/routing/presentation/cubit/routing_cubit.dart';
import 'package:local_route/routing/presentation/cubit/routing_state.dart';
import 'package:local_route/routing/repository/routing_repository.dart';
import 'support/routing_fakes.dart';

void main() {
  late ControlledService service;
  late RoutingCubit cubit;
  setUp(() {
    service = ControlledService();
    cubit = RoutingCubit(repository: RoutingRepository(service: service));
  });
  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });
  void endpoints() {
    cubit.selectPosition(origin.latitude, origin.longitude);
    cubit.selectPosition(destination.latitude, destination.longitude);
  }

  test('map readiness emits once and preserves endpoint state', () async {
    cubit.selectPosition(origin.latitude, origin.longitude);
    final changes = <bool>[];
    final subscription = cubit.stream.listen(
      (state) => changes.add(state.isMapReady),
    );
    cubit.markMapReady();
    cubit.markMapReady();
    await cubit.close();
    expect(changes, [true]);
    expect(cubit.state.origin, origin);
    await subscription.cancel();
  });
  test(
    'selection eligibility, missing endpoints and invalid coordinate',
    () async {
      expect(cubit.state.canRequest, isFalse);
      await cubit.requestRoute();
      expect(cubit.state.failure, RoutingFailure.missingEndpoints);
      cubit.selectPosition(origin.latitude, origin.longitude);
      expect(cubit.state.origin, origin);
      expect(cubit.state.selecting, Endpoint.destination);
      expect(cubit.state.canRequest, isFalse);
      cubit.selectPosition(destination.latitude, destination.longitude);
      expect(cubit.state.destination, destination);
      expect(cubit.state.canRequest, isTrue);
      cubit.selectPosition(double.nan, 0);
      expect(cubit.state.failure, RoutingFailure.invalidCoordinate);
      expect(service.pending, isEmpty);
    },
  );
  test('loading, duplicate prevention and success', () async {
    endpoints();
    final request = cubit.requestRoute();
    expect(cubit.state.isLoading, isTrue);
    expect(cubit.state.canRequest, isFalse);
    await cubit.requestRoute();
    expect(service.pending.length, 1);
    service.pending.single.complete(exampleRoute());
    await request;
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.route!.distanceMeters, 2500);
    expect(cubit.state.failure, isNull);
  });
  test('safe error, explicit retry, successful retry', () async {
    endpoints();
    final request = cubit.requestRoute();
    service.pending.single.completeError(RoutingFailure.network);
    await request;
    expect(cubit.state.failure, RoutingFailure.network);
    expect(cubit.state.canRequest, isTrue);
    final retry = cubit.requestRoute();
    expect(cubit.state.failure, isNull);
    service.pending.last.complete(exampleRoute());
    await retry;
    expect(cubit.state.route, isNotNull);
  });
  test('unexpected exception is sanitized', () async {
    endpoints();
    final request = cubit.requestRoute();
    service.pending.single.completeError(
      StateError('secret transport details'),
    );
    await request;
    expect(cubit.state.failure, RoutingFailure.unavailable);
  });
  for (final endpoint in Endpoint.values) {
    test('changing $endpoint clears obsolete route and error', () async {
      endpoints();
      final request = cubit.requestRoute();
      service.pending.single.complete(exampleRoute());
      await request;
      cubit.selectEndpoint(endpoint);
      cubit.selectPosition(24.89, 67.04);
      expect(cubit.state.route, isNull);
      expect(cubit.state.failure, isNull);
      final failure = cubit.requestRoute();
      service.pending.last.completeError(RoutingFailure.noRoute);
      await failure;
      cubit.selectPosition(24.9, 67.05);
      expect(cubit.state.failure, isNull);
    });
  }
  for (final staleError in [false, true]) {
    test(
      'stale ${staleError ? 'error' : 'success'} cannot overwrite newer success',
      () async {
        endpoints();
        final a = cubit.requestRoute();
        cubit.selectPosition(24.89, 67.04);
        final b = cubit.requestRoute();
        final newest = exampleRoute();
        service.pending[1].complete(newest);
        await b;
        if (staleError) {
          service.pending[0].completeError(RoutingFailure.network);
        } else {
          service.pending[0].complete(exampleRoute());
        }
        await a;
        expect(cubit.state.route, same(newest));
        expect(cubit.state.destination!.latitude, 24.89);
        expect(cubit.state.failure, isNull);
      },
    );
  }
  test('reset invalidates a pending request and preserves readiness', () async {
    cubit.markMapReady();
    endpoints();
    final request = cubit.requestRoute();
    cubit.reset();
    service.pending.single.complete(exampleRoute());
    await request;
    expect(cubit.state.origin, isNull);
    expect(cubit.state.destination, isNull);
    expect(cubit.state.route, isNull);
    expect(cubit.state.isMapReady, isTrue);
  });
  test('closed cubit ignores completion', () async {
    endpoints();
    final request = cubit.requestRoute();
    await cubit.close();
    service.pending.single.completeError(RoutingFailure.network);
    await request;
  });
}
