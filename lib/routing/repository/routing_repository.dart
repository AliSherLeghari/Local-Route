import '../services/routing_service.dart';

/// The Cubit's future entry point for road routing operations.
///
/// Keep this boundary when adding routing: the service can later call our
/// backend without making the UI depend on a particular routing provider.
class RoutingRepository {
  const RoutingRepository({required this.service});

  final RoutingService service;
}
