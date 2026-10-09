import '../../models/route_point.dart';
import '../../models/route_result.dart';
import '../../models/routing_failure.dart';

enum Endpoint { origin, destination }

/// Map readiness means controller attachment, not successful tile downloads.
class RoutingState {
  const RoutingState({
    this.isMapReady = false,
    this.origin,
    this.destination,
    this.selecting = Endpoint.origin,
    this.isLoading = false,
    this.route,
    this.failure,
  });

  final bool isMapReady;
  final RoutePoint? origin;
  final RoutePoint? destination;
  final Endpoint selecting;
  final bool isLoading;
  final RouteResult? route;
  final RoutingFailure? failure;
  bool get canRequest => origin != null && destination != null && !isLoading;
}
