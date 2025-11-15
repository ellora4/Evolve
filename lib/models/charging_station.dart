
class ChargingStation {
  const ChargingStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.availablePorts,
    this.powerKw,
    this.network,
    this.plugTypes = const <String>[],
    this.notes,
  });

  final String id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final int? availablePorts;
  final double? powerKw;
  final String? network;
  final List<String> plugTypes;
  final String? notes;

  LatLng get location => LatLng(latitude, longitude);

  String get plugTypesLabel => plugTypes.join(', ');
}

class LatLng {
  const LatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}
