import 'package:flutter_test/flutter_test.dart';
import 'package:local_route/routing/models/route_point.dart';
import 'package:local_route/routing/models/route_result.dart';
import 'support/routing_fakes.dart';

void main() {
  test('coordinates include boundaries and compare by value', () {
    expect(RoutePoint(latitude: -90, longitude: -180).latitude, -90);
    expect(RoutePoint(latitude: 90, longitude: 180).longitude, 180);
    expect(RoutePoint(latitude: 24.86, longitude: 67.01), origin);
    expect(
      RoutePoint(latitude: 24.86, longitude: 67.01).hashCode,
      origin.hashCode,
    );
  });
  for (final value in [
    -91.0,
    91.0,
    double.nan,
    double.infinity,
    double.negativeInfinity,
  ]) {
    test(
      'rejects latitude $value',
      () => expect(
        () => RoutePoint(latitude: value, longitude: 0),
        throwsArgumentError,
      ),
    );
  }
  for (final value in [
    -181.0,
    181.0,
    double.nan,
    double.infinity,
    double.negativeInfinity,
  ]) {
    test(
      'rejects longitude $value',
      () => expect(
        () => RoutePoint(latitude: 0, longitude: value),
        throwsArgumentError,
      ),
    );
  }
  test('result copies geometry and prevents mutation', () {
    final geometry = [origin, destination];
    final result = RouteResult(
      geometry: geometry,
      distanceMeters: 0,
      duration: Duration.zero,
    );
    geometry.clear();
    expect(result.geometry.length, 2);
    expect(() => result.geometry.clear(), throwsUnsupportedError);
  });
  test('invalid result metrics and short geometry rejected', () {
    for (final value in [-1.0, double.nan, double.infinity]) {
      expect(
        () => RouteResult(
          geometry: [origin, destination],
          distanceMeters: value,
          duration: Duration.zero,
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => RouteResult(
        geometry: [origin],
        distanceMeters: 1,
        duration: Duration.zero,
      ),
      throwsArgumentError,
    );
    expect(
      () => RouteResult(
        geometry: [origin, destination],
        distanceMeters: 1,
        duration: const Duration(seconds: -1),
      ),
      throwsArgumentError,
    );
  });
}
