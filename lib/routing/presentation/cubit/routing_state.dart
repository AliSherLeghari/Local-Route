/// Map readiness means its controller is attached, not that tiles have loaded.
class RoutingState {
  const RoutingState({this.isMapReady = false});

  final bool isMapReady;
}
