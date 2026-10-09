class RoutePoint {
  RoutePoint({required this.latitude, required this.longitude}) {
    if (!latitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        !longitude.isFinite ||
        longitude < -180 ||
        longitude > 180) {
      throw ArgumentError('Invalid route coordinate.');
    }
  }

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is RoutePoint &&
      latitude == other.latitude &&
      longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}
