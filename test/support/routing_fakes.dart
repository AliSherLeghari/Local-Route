import 'dart:async';
import 'package:http/testing.dart';
import 'package:local_route/routing/models/route_point.dart';
import 'package:local_route/routing/models/route_result.dart';
import 'package:local_route/routing/services/routing_service.dart';

final origin = RoutePoint(latitude: 24.86, longitude: 67.01);
final destination = RoutePoint(latitude: 24.88, longitude: 67.03);
RouteResult exampleRoute() => RouteResult(
  geometry: [
    origin,
    RoutePoint(latitude: 24.87, longitude: 67.015),
    destination,
  ],
  distanceMeters: 2500,
  duration: const Duration(minutes: 8),
);

Map<String, dynamic> providerRoute() => {
  'paths': [
    <String, dynamic>{
      'points_encoded': false,
      'distance': 2500,
      'time': 480000,
      'points': <String, dynamic>{
        'type': 'LineString',
        'coordinates': [
          [67.01, 24.86],
          [67.015, 24.87],
          [67.03, 24.88],
        ],
      },
    },
  ],
};

class ControlledService extends RoutingService {
  ControlledService()
    : super(
        apiKey: '',
        client: MockClient(
          (_) async => throw StateError('Tests must not send HTTP'),
        ),
      );
  final pending = <Completer<RouteResult>>[];
  final endpoints = <(RoutePoint, RoutePoint)>[];
  @override
  Future<RouteResult> route(RoutePoint origin, RoutePoint destination) {
    endpoints.add((origin, destination));
    final request = Completer<RouteResult>();
    pending.add(request);
    return request.future;
  }
}
