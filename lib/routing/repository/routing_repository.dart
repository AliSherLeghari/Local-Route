import '../services/routing_service.dart';
import '../models/route_point.dart';
import '../models/route_result.dart';

/// The Cubit's provider-neutral entry point for road routing operations.
///
/// Keep this boundary when adding routing: the service can later call our
/// backend without making the UI depend on a particular routing provider.
class RoutingRepository {
  const RoutingRepository({required this.service});

  final RoutingService service;

  Future<RouteResult> route(RoutePoint origin, RoutePoint destination) =>
      service.route(origin, destination);
}
