import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/route_point.dart';
import '../models/route_result.dart';
import '../models/routing_failure.dart';

/// GraphHopper transport and schema stay entirely inside this boundary.
class RoutingService {
  RoutingService({
    required http.Client client,
    required String apiKey,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client,
       _apiKey = apiKey.trim();

  final http.Client _client;
  final String _apiKey;
  final Duration timeout;
  static const maxResponseBytes = 2 * 1024 * 1024;
  static const maxGeometryPoints = 25000;

  Future<RouteResult> route(RoutePoint origin, RoutePoint destination) async {
    if (_apiKey.isEmpty || _apiKey.startsWith('REPLACE_')) {
      throw RoutingFailure.configuration;
    }
    final uri = Uri.https('graphhopper.com', '/api/1/route', {
      'key': _apiKey,
      'profile': 'car',
      // GET inputs are latitude,longitude; GeoJSON outputs are longitude,latitude.
      'point': [
        '${origin.latitude},${origin.longitude}',
        '${destination.latitude},${destination.longitude}',
      ],
      'points_encoded': 'false', 'calc_points': 'true',
      'instructions': 'false', 'elevation': 'false',
    });
    final abort = Completer<void>();
    try {
      return await _request(uri, abort.future).timeout(timeout);
    } on RoutingFailure {
      rethrow;
    } on TimeoutException {
      throw RoutingFailure.timeout;
    } on http.ClientException {
      throw RoutingFailure.network;
    } on FormatException {
      throw RoutingFailure.malformed;
    } on ArgumentError {
      throw RoutingFailure.malformed;
    } catch (_) {
      // Never propagate transport messages: they may contain key/coordinates.
      throw RoutingFailure.unavailable;
    } finally {
      abort.complete();
    }
  }

  Future<RouteResult> _request(Uri uri, Future<void> abort) async {
    final request = http.AbortableRequest('GET', uri, abortTrigger: abort)
      ..followRedirects = false
      ..headers['Accept'] = 'application/json';
    final response = await _client.send(request);
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw RoutingFailure.configuration;
    }
    if (response.statusCode == 429) throw RoutingFailure.rateLimited;
    if (response.statusCode != 200 && response.statusCode != 400) {
      throw RoutingFailure.unavailable;
    }
    if ((response.contentLength ?? 0) > maxResponseBytes) {
      throw RoutingFailure.malformed;
    }
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > maxResponseBytes) {
        throw RoutingFailure.malformed;
      }
      bytes.addAll(chunk);
    }
    final json = jsonDecode(utf8.decode(bytes));
    if (json is! Map<String, dynamic>) throw RoutingFailure.malformed;
    if (response.statusCode == 400) {
      // Inspect known machine-readable types, never provider error text.
      final hints = json['hints'];
      if (hints is List &&
          hints.any(
            (hint) =>
                hint is Map &&
                const [
                  'com.graphhopper.util.exceptions.ConnectionNotFoundException',
                  'com.graphhopper.util.exceptions.PointNotFoundException',
                ].contains(hint['details']),
          )) {
        throw RoutingFailure.noRoute;
      }
      throw RoutingFailure.configuration;
    }
    final paths = json['paths'];
    if (paths is! List) throw RoutingFailure.malformed;
    if (paths.isEmpty) throw RoutingFailure.noRoute;
    final path = paths.first;
    if (path is! Map || path['points_encoded'] != false) {
      throw RoutingFailure.malformed;
    }
    final points = path['points'];
    if (points is! Map || points['type'] != 'LineString') {
      throw RoutingFailure.malformed;
    }
    final coordinates = points['coordinates'];
    if (coordinates is! List ||
        coordinates.length < 2 ||
        coordinates.length > maxGeometryPoints) {
      throw RoutingFailure.malformed;
    }
    final geometry = <RoutePoint>[];
    for (final pair in coordinates) {
      if (pair is! List ||
          pair.length != 2 ||
          pair[0] is! num ||
          pair[1] is! num) {
        throw RoutingFailure.malformed;
      }
      geometry.add(
        RoutePoint(
          latitude: (pair[1] as num).toDouble(),
          longitude: (pair[0] as num).toDouble(),
        ),
      );
    }
    final distance = path['distance'];
    final milliseconds = path['time'];
    if (distance is! num ||
        !distance.isFinite ||
        distance < 0 ||
        distance > 100000000 ||
        milliseconds is! int ||
        milliseconds < 0 ||
        milliseconds > 31536000000) {
      throw RoutingFailure.malformed;
    }
    return RouteResult(
      geometry: geometry,
      distanceMeters: distance.toDouble(),
      duration: Duration(milliseconds: milliseconds),
    );
  }
}
