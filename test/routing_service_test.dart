import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:local_route/routing/models/routing_failure.dart';
import 'package:local_route/routing/services/routing_service.dart';
import 'support/routing_fakes.dart';

void main() {
  RoutingService service(
    http.Client client, {
    String key = 'test-only-placeholder',
    Duration timeout = const Duration(seconds: 1),
  }) {
    addTearDown(client.close);
    return RoutingService(client: client, apiKey: key, timeout: timeout);
  }

  test(
    'fixed HTTPS host, parameters, order, no redirects and parsed units',
    () async {
      final client = MockClient((request) async {
        expect(request.url.scheme, 'https');
        expect(request.url.host, 'graphhopper.com');
        expect(request.url.path, '/api/1/route');
        expect(request.method, 'GET');
        expect(request.followRedirects, isFalse);
        expect(request.url.queryParametersAll['point'], [
          '24.86,67.01',
          '24.88,67.03',
        ]);
        expect(request.url.queryParameters['profile'], 'car');
        expect(request.url.queryParameters['points_encoded'], 'false');
        expect(request.url.queryParameters['instructions'], 'false');
        expect(request.url.queryParameters['elevation'], 'false');
        expect(request.url.queryParameters.containsKey('algorithm'), isFalse);
        expect(request.url.queryParameters['key'], 'test-only-placeholder');
        return http.Response(jsonEncode(providerRoute()), 200);
      });
      final route = await service(client).route(origin, destination);
      expect(route.geometry.first, origin);
      expect(route.geometry.last, destination);
      expect(route.geometry.length, 3);
      expect(route.geometry[1].longitude, 67.015);
      expect(route.distanceMeters, 2500);
      expect(route.duration, const Duration(minutes: 8));
    },
  );
  for (final status in [401, 403, 429, 500, 503, 302, 404]) {
    test('maps HTTP $status without exposing response', () async {
      final expected = status == 401 || status == 403
          ? RoutingFailure.configuration
          : status == 429
          ? RoutingFailure.rateLimited
          : RoutingFailure.unavailable;
      await expectLater(
        service(
          MockClient(
            (_) async => http.Response('sensitive-provider-body', status),
          ),
        ).route(origin, destination),
        throwsA(expected),
      );
    });
  }
  for (final key in ['', '  ', 'REPLACE_WITH_YOUR_OWN_DEVELOPMENT_KEY']) {
    test('missing or placeholder key fails before HTTP ($key)', () async {
      final client = MockClient(
        (_) async => throw StateError('Must not request'),
      );
      await expectLater(
        service(client, key: key).route(origin, destination),
        throwsA(RoutingFailure.configuration),
      );
    });
  }
  test('no routes and typed no-route errors', () async {
    await expectLater(
      service(
        MockClient((_) async => http.Response('{"paths":[]}', 200)),
      ).route(origin, destination),
      throwsA(RoutingFailure.noRoute),
    );
    for (final type in [
      'ConnectionNotFoundException',
      'PointNotFoundException',
    ]) {
      await expectLater(
        service(
          MockClient(
            (_) async => http.Response(
              jsonEncode({
                'hints': [
                  {'details': 'com.graphhopper.util.exceptions.$type'},
                ],
              }),
              400,
            ),
          ),
        ).route(origin, destination),
        throwsA(RoutingFailure.noRoute),
      );
    }
  });
  test('unrecognized bad request is safe configuration failure', () async {
    await expectLater(
      service(
        MockClient((_) async => http.Response('{"message":"private"}', 400)),
      ).route(origin, destination),
      throwsA(RoutingFailure.configuration),
    );
  });
  for (final body in [
    'not json',
    '[]',
    '{}',
    '{"paths":[null]}',
    '{"paths":null}',
  ]) {
    test('rejects malformed document $body', () async {
      await expectLater(
        service(
          MockClient((_) async => http.Response(body, 200)),
        ).route(origin, destination),
        throwsA(RoutingFailure.malformed),
      );
    });
  }
  final invalidFields = <String, Map<String, dynamic>>{
    'encoded geometry': {'points_encoded': true},
    'missing geometry': {'points': null},
    'wrong geometry type': {
      'points': {
        'type': 'Point',
        'coordinates': [67, 24],
      },
    },
    'short geometry': {
      'points': {
        'type': 'LineString',
        'coordinates': [
          [67, 24],
        ],
      },
    },
    'invalid coordinate': {
      'points': {
        'type': 'LineString',
        'coordinates': [
          [181, 24],
          [67, 24],
        ],
      },
    },
    'non-numeric coordinate': {
      'points': {
        'type': 'LineString',
        'coordinates': [
          ['67', 24],
          [67, 24],
        ],
      },
    },
    'extra dimension': {
      'points': {
        'type': 'LineString',
        'coordinates': [
          [67, 24, 0],
          [67, 24],
        ],
      },
    },
    'negative distance': {'distance': -1},
    'nonfinite distance': {'distance': 'Infinity'},
    'missing distance': {'distance': null},
    'negative duration': {'time': -1},
    'fractional duration': {'time': 2.5},
    'excess duration': {'time': 31536000001},
  };
  for (final entry in invalidFields.entries) {
    test('rejects ${entry.key}', () async {
      final body = providerRoute();
      (body['paths'] as List).first.addAll(entry.value);
      await expectLater(
        service(
          MockClient((_) async => http.Response(jsonEncode(body), 200)),
        ).route(origin, destination),
        throwsA(RoutingFailure.malformed),
      );
    });
  }
  test('geometry point limit', () async {
    final body = providerRoute();
    (body['paths'] as List).first['points']['coordinates'] = List.generate(
      RoutingService.maxGeometryPoints + 1,
      (_) => [67, 24],
    );
    await expectLater(
      service(
        MockClient((_) async => http.Response(jsonEncode(body), 200)),
      ).route(origin, destination),
      throwsA(RoutingFailure.malformed),
    );
  });
  test('response limit without content length', () async {
    final client = MockClient.streaming(
      (_, _) async => http.StreamedResponse(
        Stream.value(List.filled(RoutingService.maxResponseBytes + 1, 32)),
        200,
      ),
    );
    await expectLater(
      service(client).route(origin, destination),
      throwsA(RoutingFailure.malformed),
    );
  });
  test('response declared length limit', () async {
    final client = MockClient.streaming(
      (_, _) async => http.StreamedResponse(
        const Stream.empty(),
        200,
        contentLength: RoutingService.maxResponseBytes + 1,
      ),
    );
    await expectLater(
      service(client).route(origin, destination),
      throwsA(RoutingFailure.malformed),
    );
  });
  test('transport failure is sanitized', () async {
    await expectLater(
      service(
        MockClient(
          (_) async => throw http.ClientException(
            'key=test-only-placeholder; coordinates',
          ),
        ),
      ).route(origin, destination),
      throwsA(RoutingFailure.network),
    );
  });
  test('timeout includes response body and aborts transport', () async {
    final client = _HangingClient();
    await expectLater(
      service(
        client,
        timeout: const Duration(milliseconds: 10),
      ).route(origin, destination),
      throwsA(RoutingFailure.timeout),
    );
    await Future<void>.delayed(Duration.zero);
    expect(client.aborted, isTrue);
  });
}

class _HangingClient extends http.BaseClient {
  bool aborted = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    (request as http.AbortableRequest).abortTrigger!.then(
      (_) => aborted = true,
    );
    return http.StreamedResponse(
      Stream<List<int>>.fromFuture(Completer<List<int>>().future),
      200,
    );
  }
}
