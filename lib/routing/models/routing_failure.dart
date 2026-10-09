enum RoutingFailure implements Exception {
  missingEndpoints('Select an origin and destination first.'),
  invalidCoordinate('Choose a valid position on the map.'),
  tooManyWaypoints('Choose no more than three intermediate waypoints.'),
  noRoute('No driving route found. Try points nearer public roads.'),
  timeout('The route took too long. Try again.'),
  network('Unable to connect. Check your internet and try again.'),
  unavailable('Routing is unavailable right now. Try again later.'),
  rateLimited('Too many route requests. Wait a minute before trying again.'),
  configuration('Routing is not configured. Check the development setup.'),
  malformed('The routing service returned an unusable route. Try again later.');

  const RoutingFailure(this.message);
  final String message;
}
