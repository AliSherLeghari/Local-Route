import '../../models/route_point.dart';
import '../../models/route_result.dart';
import '../../models/routing_failure.dart';
import '../../models/routing_limits.dart';

enum Endpoint { origin, destination }

const _unchanged = Object();

/// Results belong to the current coordinates; Cubit invalidates them on edits.
class RoutingState {
  RoutingState({
    this.isMapReady = false,
    this.origin,
    this.destination,
    this.selecting = Endpoint.origin,
    List<RoutePoint> waypoints = const [],
    this.isAddingWaypoint = false,
    this.selectedWaypointIndex,
    this.conventionalRoute,
    this.preferredRoute,
    this.isConventionalLoading = false,
    this.isPreferredLoading = false,
    this.conventionalFailure,
    this.preferredFailure,
    this.inputFailure,
  }) : waypoints = List.unmodifiable(waypoints) {
    if (waypoints.length > maxIntermediateWaypoints) {
      throw ArgumentError('Too many intermediate waypoints.');
    }
  }

  final bool isMapReady;
  final RoutePoint? origin;
  final RoutePoint? destination;
  final Endpoint selecting;
  final List<RoutePoint> waypoints;
  final bool isAddingWaypoint;
  final int? selectedWaypointIndex;
  final RouteResult? conventionalRoute;
  final RouteResult? preferredRoute;
  final bool isConventionalLoading;
  final bool isPreferredLoading;
  final RoutingFailure? conventionalFailure;
  final RoutingFailure? preferredFailure;
  final RoutingFailure? inputFailure;

  // Compatibility with the conventional-only map screen until Stage 3.
  RouteResult? get route => conventionalRoute;
  RoutingFailure? get failure =>
      inputFailure ?? conventionalFailure ?? preferredFailure;
  bool get isLoading => isConventionalLoading || isPreferredLoading;
  bool get canAddWaypoint => waypoints.length < maxIntermediateWaypoints;
  bool get canRequest =>
      origin != null &&
      destination != null &&
      ((!isConventionalLoading && conventionalRoute == null) ||
          (waypoints.isNotEmpty &&
              !isPreferredLoading &&
              preferredRoute == null));
  bool get hasComparison =>
      waypoints.isNotEmpty &&
      conventionalRoute != null &&
      preferredRoute != null;

  /// Preferred minus conventional, before any display rounding.
  double? get distanceDifferenceMeters => hasComparison
      ? preferredRoute!.distanceMeters - conventionalRoute!.distanceMeters
      : null;
  Duration? get durationDifference => hasComparison
      ? preferredRoute!.duration - conventionalRoute!.duration
      : null;

  RoutingState copyWith({
    bool? isMapReady,
    RoutePoint? origin,
    RoutePoint? destination,
    Endpoint? selecting,
    List<RoutePoint>? waypoints,
    bool? isAddingWaypoint,
    Object? selectedWaypointIndex = _unchanged,
    Object? conventionalRoute = _unchanged,
    Object? preferredRoute = _unchanged,
    bool? isConventionalLoading,
    bool? isPreferredLoading,
    Object? conventionalFailure = _unchanged,
    Object? preferredFailure = _unchanged,
    Object? inputFailure = _unchanged,
  }) => RoutingState(
    isMapReady: isMapReady ?? this.isMapReady,
    origin: origin ?? this.origin,
    destination: destination ?? this.destination,
    selecting: selecting ?? this.selecting,
    waypoints: waypoints ?? this.waypoints,
    isAddingWaypoint: isAddingWaypoint ?? this.isAddingWaypoint,
    selectedWaypointIndex: identical(selectedWaypointIndex, _unchanged)
        ? this.selectedWaypointIndex
        : selectedWaypointIndex as int?,
    conventionalRoute: identical(conventionalRoute, _unchanged)
        ? this.conventionalRoute
        : conventionalRoute as RouteResult?,
    preferredRoute: identical(preferredRoute, _unchanged)
        ? this.preferredRoute
        : preferredRoute as RouteResult?,
    isConventionalLoading: isConventionalLoading ?? this.isConventionalLoading,
    isPreferredLoading: isPreferredLoading ?? this.isPreferredLoading,
    conventionalFailure: identical(conventionalFailure, _unchanged)
        ? this.conventionalFailure
        : conventionalFailure as RoutingFailure?,
    preferredFailure: identical(preferredFailure, _unchanged)
        ? this.preferredFailure
        : preferredFailure as RoutingFailure?,
    inputFailure: identical(inputFailure, _unchanged)
        ? this.inputFailure
        : inputFailure as RoutingFailure?,
  );
}
