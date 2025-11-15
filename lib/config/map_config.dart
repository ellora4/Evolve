import '../models/charging_station.dart';

/// Central place for Mapbox configuration so we can keep the token,
/// style identifier, and default camera settings consistent.
class MapConfig {
  static const String accessToken =
      'pk.eyJ1IjoianVsaWFhYW5kZXYiLCJhIjoiY21nbzU4bGVtMTk4ODJqcHlwaGx1d2x3dyJ9.04tgaq2_FFeybxxTPtz12w';

  static final LatLng defaultCenter = LatLng(6.524379, 3.379206); // Lagos, NG
  static const double defaultZoom = 14;
}
