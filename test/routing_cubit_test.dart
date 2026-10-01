import 'package:flutter_test/flutter_test.dart';
import 'package:local_route/routing/presentation/cubit/routing_cubit.dart';
import 'package:local_route/routing/repository/routing_repository.dart';
import 'package:local_route/routing/services/routing_service.dart';

void main() {
  test('Map readiness emits once even if the callback repeats', () async {
    final cubit = RoutingCubit(
      repository: const RoutingRepository(service: RoutingService()),
    );
    expect(cubit.state.isMapReady, isFalse);
    final changes = <bool>[];
    final subscription = cubit.stream.listen(
      (state) => changes.add(state.isMapReady),
    );
    cubit.markMapReady();
    cubit.markMapReady();
    await cubit.close();
    expect(changes, [true]);
    await subscription.cancel();
  });
}
