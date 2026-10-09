import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/route_point.dart';
import '../../models/routing_failure.dart';
import '../../repository/routing_repository.dart';
import 'routing_state.dart';

class RoutingCubit extends Cubit<RoutingState> {
  RoutingCubit({required this.repository}) : super(const RoutingState());

  final RoutingRepository repository;
  int _generation = 0;

  void markMapReady() {
    if (!state.isMapReady) {
      emit(
        RoutingState(
          isMapReady: true,
          origin: state.origin,
          destination: state.destination,
          selecting: state.selecting,
          isLoading: state.isLoading,
          route: state.route,
          failure: state.failure,
        ),
      );
    }
  }

  void selectEndpoint(Endpoint endpoint) {
    emit(
      RoutingState(
        isMapReady: state.isMapReady,
        origin: state.origin,
        destination: state.destination,
        selecting: endpoint,
        isLoading: state.isLoading,
        route: state.route,
        failure: state.failure,
      ),
    );
  }

  void selectPosition(double latitude, double longitude) {
    RoutePoint point;
    try {
      point = RoutePoint(latitude: latitude, longitude: longitude);
    } on ArgumentError {
      _generation++;
      emit(
        RoutingState(
          isMapReady: state.isMapReady,
          origin: state.origin,
          destination: state.destination,
          selecting: state.selecting,
          failure: RoutingFailure.invalidCoordinate,
        ),
      );
      return;
    }
    _generation++;
    emit(
      RoutingState(
        isMapReady: state.isMapReady,
        origin: state.selecting == Endpoint.origin ? point : state.origin,
        destination: state.selecting == Endpoint.destination
            ? point
            : state.destination,
        selecting: Endpoint.destination,
      ),
    );
  }

  void reset() {
    _generation++;
    emit(RoutingState(isMapReady: state.isMapReady));
  }

  Future<void> requestRoute() async {
    if (state.isLoading) return;
    final origin = state.origin;
    final destination = state.destination;
    if (origin == null || destination == null) {
      emit(
        RoutingState(
          isMapReady: state.isMapReady,
          origin: origin,
          destination: destination,
          selecting: state.selecting,
          failure: RoutingFailure.missingEndpoints,
        ),
      );
      return;
    }
    final generation = ++_generation;
    emit(
      RoutingState(
        isMapReady: state.isMapReady,
        origin: origin,
        destination: destination,
        selecting: state.selecting,
        isLoading: true,
      ),
    );
    try {
      final result = await repository.route(origin, destination);
      if (isClosed || generation != _generation) return;
      emit(
        RoutingState(
          isMapReady: state.isMapReady,
          origin: origin,
          destination: destination,
          selecting: state.selecting,
          route: result,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _generation) return;
      emit(
        RoutingState(
          isMapReady: state.isMapReady,
          origin: origin,
          destination: destination,
          selecting: state.selecting,
          failure: error is RoutingFailure ? error : RoutingFailure.unavailable,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _generation++;
    return super.close();
  }
}
