import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/route_point.dart';
import '../../models/routing_failure.dart';
import '../../repository/routing_repository.dart';
import 'routing_state.dart';

class RoutingCubit extends Cubit<RoutingState> {
  RoutingCubit({required this.repository}) : super(RoutingState());

  final RoutingRepository repository;
  int _conventionalGeneration = 0;
  int _preferredGeneration = 0;

  void markMapReady() {
    if (!isClosed && !state.isMapReady) emit(state.copyWith(isMapReady: true));
  }

  void selectEndpoint(Endpoint endpoint) {
    if (isClosed) return;
    emit(
      state.copyWith(
        selecting: endpoint,
        isAddingWaypoint: false,
        selectedWaypointIndex: null,
        inputFailure: null,
      ),
    );
  }

  bool beginAddWaypoint() {
    if (isClosed) return false;
    if (!state.canAddWaypoint) {
      emit(state.copyWith(inputFailure: RoutingFailure.tooManyWaypoints));
      return false;
    }
    emit(
      state.copyWith(
        isAddingWaypoint: true,
        selectedWaypointIndex: null,
        inputFailure: null,
      ),
    );
    return true;
  }

  bool _validIndex(int index) => index >= 0 && index < state.waypoints.length;

  /// Invalid indices are rejected as no-ops, without disturbing valid results.
  bool selectWaypoint(int index) {
    if (isClosed || !_validIndex(index)) return false;
    emit(
      state.copyWith(
        isAddingWaypoint: false,
        selectedWaypointIndex: index,
        inputFailure: null,
      ),
    );
    return true;
  }

  bool addWaypoint(RoutePoint point) {
    if (isClosed) return false;
    if (!state.canAddWaypoint) {
      emit(state.copyWith(inputFailure: RoutingFailure.tooManyWaypoints));
      return false;
    }
    _changeWaypoints([...state.waypoints, point]);
    return true;
  }

  bool replaceWaypoint(int index, RoutePoint point) {
    if (isClosed || !_validIndex(index)) return false;
    final points = [...state.waypoints];
    points[index] = point;
    _changeWaypoints(points);
    return true;
  }

  bool removeWaypoint(int index) {
    if (isClosed || !_validIndex(index)) return false;
    _changeWaypoints([...state.waypoints]..removeAt(index));
    return true;
  }

  /// [toIndex] is the desired final index, not a drag/drop insertion offset.
  bool reorderWaypoint(int fromIndex, int toIndex) {
    if (isClosed || !_validIndex(fromIndex) || !_validIndex(toIndex)) {
      return false;
    }
    if (fromIndex == toIndex) return true;
    final points = [...state.waypoints];
    points.insert(toIndex, points.removeAt(fromIndex));
    _changeWaypoints(points);
    return true;
  }

  void _changeWaypoints(List<RoutePoint> points) {
    _preferredGeneration++;
    emit(
      state.copyWith(
        waypoints: points,
        isAddingWaypoint: false,
        selectedWaypointIndex: null,
        preferredRoute: null,
        preferredFailure: null,
        isPreferredLoading: false,
        inputFailure: null,
      ),
    );
  }

  void selectPosition(double latitude, double longitude) {
    if (isClosed) return;
    RoutePoint point;
    try {
      point = RoutePoint(latitude: latitude, longitude: longitude);
    } on ArgumentError {
      emit(state.copyWith(inputFailure: RoutingFailure.invalidCoordinate));
      return;
    }
    if (state.isAddingWaypoint) {
      addWaypoint(point);
    } else if (state.selectedWaypointIndex case final int index) {
      replaceWaypoint(index, point);
    } else {
      _conventionalGeneration++;
      _preferredGeneration++;
      emit(
        state.copyWith(
          origin: state.selecting == Endpoint.origin ? point : state.origin,
          destination: state.selecting == Endpoint.destination
              ? point
              : state.destination,
          selecting: Endpoint.destination,
          conventionalRoute: null,
          preferredRoute: null,
          conventionalFailure: null,
          preferredFailure: null,
          isConventionalLoading: false,
          isPreferredLoading: false,
          inputFailure: null,
        ),
      );
    }
  }

  void reset() {
    if (isClosed) return;
    _conventionalGeneration++;
    _preferredGeneration++;
    emit(RoutingState(isMapReady: state.isMapReady));
  }

  /// Only explicit submission starts requests. Each branch handles its own
  /// failure; valid and in-flight results are reused for the current inputs.
  Future<void> requestRoute() async {
    if (isClosed) return;
    final origin = state.origin;
    final destination = state.destination;
    if (origin == null || destination == null) {
      emit(state.copyWith(inputFailure: RoutingFailure.missingEndpoints));
      return;
    }
    final conventional =
        state.conventionalRoute == null && !state.isConventionalLoading;
    final preferred =
        state.waypoints.isNotEmpty &&
        state.preferredRoute == null &&
        !state.isPreferredLoading;
    if (!conventional && !preferred) return;
    final points = state.waypoints;
    final conventionalGeneration = conventional
        ? ++_conventionalGeneration
        : _conventionalGeneration;
    final preferredGeneration = preferred
        ? ++_preferredGeneration
        : _preferredGeneration;
    emit(
      state.copyWith(
        isConventionalLoading: conventional || state.isConventionalLoading,
        isPreferredLoading: preferred || state.isPreferredLoading,
        conventionalFailure: conventional ? null : state.conventionalFailure,
        preferredFailure: preferred ? null : state.preferredFailure,
        inputFailure: null,
      ),
    );
    await Future.wait([
      if (conventional)
        _request(origin, destination, const [], false, conventionalGeneration),
      if (preferred)
        _request(origin, destination, points, true, preferredGeneration),
    ]);
  }

  Future<void> _request(
    RoutePoint origin,
    RoutePoint destination,
    List<RoutePoint> waypoints,
    bool preferred,
    int generation,
  ) async {
    bool current() =>
        !isClosed &&
        generation ==
            (preferred ? _preferredGeneration : _conventionalGeneration);
    try {
      final result = await repository.route(
        origin,
        destination,
        waypoints: waypoints,
      );
      if (!current()) return;
      emit(
        preferred
            ? state.copyWith(
                preferredRoute: result,
                isPreferredLoading: false,
                preferredFailure: null,
              )
            : state.copyWith(
                conventionalRoute: result,
                isConventionalLoading: false,
                conventionalFailure: null,
              ),
      );
    } catch (error) {
      if (!current()) return;
      final failure = error is RoutingFailure
          ? error
          : RoutingFailure.unavailable;
      emit(
        preferred
            ? state.copyWith(
                preferredFailure: failure,
                isPreferredLoading: false,
              )
            : state.copyWith(
                conventionalFailure: failure,
                isConventionalLoading: false,
              ),
      );
    }
  }

  @override
  Future<void> close() {
    _conventionalGeneration++;
    _preferredGeneration++;
    return super.close();
  }
}
