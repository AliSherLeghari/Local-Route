import 'route_point.dart';

class RouteResult {
  RouteResult({
    required List<RoutePoint> geometry,
    required this.distanceMeters,
    required this.duration,
  }) : geometry = List.unmodifiable(geometry) {
    if (geometry.length < 2 ||
        !distanceMeters.isFinite ||
        distanceMeters < 0 ||
        duration.isNegative) {
      throw ArgumentError('Invalid route result.');
    }
  }

  final List<RoutePoint> geometry;
  final double distanceMeters;
  final Duration duration;
}
