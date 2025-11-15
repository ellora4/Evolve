import 'dart:async';
import 'dart:convert';

import 'package:evolve/config/map_config.dart';
import 'package:evolve/models/charging_station.dart';
import 'package:evolve/services/favorites_service.dart';
import 'package:evolve/widgets/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FavoritesService _favoritesService = FavoritesService.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  mapbox.MapboxMap? _mapboxMap;
  mapbox.PointAnnotationManager? _pointManager;
  mapbox.PolylineAnnotationManager? _polylineManager;
  mapbox.Cancelable? _annotationTapSubscription;

  final Map<String, ChargingStation> _annotationToStation = {};

  StreamSubscription<geo.Position>? _positionSubscription;
  LatLng? _userLocation;
  ChargingStation? _selectedStation;

  bool _cameraCentered = false;
  bool _fetchingRoute = false;
  String? _locationStatus;
  bool _showNearestByDefault = true;

  @override
  void initState() {
    super.initState();
    _favoritesService.favorites.addListener(_onFavoritesChanged);
    _initLocationTracking();
  }

  @override
  void dispose() {
    _favoritesService.favorites.removeListener(_onFavoritesChanged);
    _positionSubscription?.cancel();
    _annotationTapSubscription?.cancel();
    _pointManager?.deleteAll();
    _polylineManager?.deleteAll();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationStatus = 'Turn on location services to find nearby chargers.';
      });
      return;
    }

    var permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }
    if (permission == geo.LocationPermission.denied ||
        permission == geo.LocationPermission.deniedForever) {
      setState(() {
        _locationStatus =
            'Location permission is required to show your position.';
      });
      return;
    }

    final position = await geo.Geolocator.getCurrentPosition(
      desiredAccuracy: geo.LocationAccuracy.high,
    );
    _handlePosition(position);

    _positionSubscription = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 25,
      ),
    ).listen(_handlePosition);
  }

  void _handlePosition(geo.Position position) {
    final current = LatLng(position.latitude, position.longitude);
    setState(() {
      _userLocation = current;
      _locationStatus = null;
    });

    _mapboxMap?.location.updateSettings(
      mapbox.LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        showAccuracyRing: true,
      ),
    );

    if (!_cameraCentered && _mapboxMap != null) {
      _cameraCentered = true;
      _mapboxMap!.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(current.longitude, current.latitude),
          ),
          zoom: MapConfig.defaultZoom,
        ),
        mapbox.MapAnimationOptions(duration: 800),
      );
    }

    if (_selectedStation == null &&
        _showNearestByDefault &&
        _favoritesService.favorites.value.isNotEmpty) {
      final nearest =
          _nearestStationFrom(current, _favoritesService.favorites.value);
      if (nearest != null) {
        _selectStation(nearest, animate: false);
      }
    }
  }

  ChargingStation? _nearestStationFrom(
      LatLng origin, List<ChargingStation> stations) {
    ChargingStation? nearest;
    double shortest = double.infinity;
    for (final station in stations) {
      final meters = geo.Geolocator.distanceBetween(
        origin.latitude,
        origin.longitude,
        station.latitude,
        station.longitude,
      );
      if (meters < shortest) {
        shortest = meters;
        nearest = station;
      }
    }
    return nearest;
  }

  void _onMapCreated(mapbox.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await mapboxMap.style.setStyleURI(mapbox.MapboxStyles.STANDARD);

    _pointManager = await mapboxMap.annotations.createPointAnnotationManager();
    _polylineManager =
        await mapboxMap.annotations.createPolylineAnnotationManager();

    _annotationTapSubscription =
        _pointManager?.tapEvents(onTap: _handleAnnotationTap);

    await _syncFavoriteAnnotations();
  }

  void _handleAnnotationTap(mapbox.PointAnnotation annotation) {
    final station = _annotationToStation[annotation.id];
    if (station != null) {
      _selectStation(station);
    }
  }

  Future<void> _syncFavoriteAnnotations() async {
    final manager = _pointManager;
    if (manager == null) return;

    await manager.deleteAll();
    _annotationToStation.clear();

    for (final station in _favoritesService.favorites.value) {
      final annotation = await manager.create(
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(station.longitude, station.latitude),
          ),
          iconImage: 'marker-15',
          iconSize: 1.4,
          textField: station.name,
          textOffset: const [0, 1.2],
        ),
      );
      _annotationToStation[annotation.id] = station;
    }
  }

  void _onFavoritesChanged() {
    _syncFavoriteAnnotations();
    final selected = _selectedStation;
    if (selected != null &&
        !_favoritesService.favorites.value
            .any((station) => station.id == selected.id)) {
      setState(() {
        _selectedStation = null;
      });
    } else {
      setState(() {});
    }
  }

  void _handleMapTap(mapbox.MapContentGestureContext context) {
    setState(() {
      _selectedStation = null;
      _showNearestByDefault = false;
    });
    _polylineManager?.deleteAll();
  }

  void _handleMapLongTap(mapbox.MapContentGestureContext context) {
    final position = context.point.coordinates;
    _promptAddStation(
      latitude: position.lat.toDouble(),
      longitude: position.lng.toDouble(),
    );
  }

  Future<void> _promptAddStation({
    required double latitude,
    required double longitude,
  }) async {
    final result = await showModalBottomSheet<_NewStationDetails>(
      context: _scaffoldKey.currentContext ?? context,
      isScrollControlled: true,
      builder: (_) => _AddStationSheet(
        latitude: latitude,
        longitude: longitude,
      ),
    );

    if (result == null) return;

    final station = ChargingStation(
      id: _favoritesService.generateId(),
      name: result.name,
      latitude: latitude,
      longitude: longitude,
      address: result.address?.isEmpty == true ? null : result.address,
      plugTypes: result.plugTypes,
      notes: result.notes?.isEmpty == true ? null : result.notes,
    );

    _favoritesService.add(station);
    await _syncFavoriteAnnotations();
    _selectStation(station);
  }

  void _selectStation(ChargingStation station, {bool animate = true}) {
    setState(() {
      _selectedStation = station;
      _showNearestByDefault = false;
    });

    final camera = mapbox.CameraOptions(
      center: mapbox.Point(
        coordinates: mapbox.Position(station.longitude, station.latitude),
      ),
      zoom: 15,
    );
    if (_mapboxMap != null) {
      if (animate) {
        _mapboxMap!.flyTo(
          camera,
          mapbox.MapAnimationOptions(duration: 800),
        );
      } else {
        _mapboxMap!.setCamera(camera);
      }
    }
  }

  Future<void> _drawRouteTo(ChargingStation station) async {
    final origin = _userLocation;
    if (origin == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waiting for your location before drawing a route.'),
          ),
        );
      }
      return;
    }

    setState(() => _fetchingRoute = true);

    try {
      final path = await _requestRoute(
        origin: origin,
        destination: station.location,
      );
      if (!mounted) return;
      final manager = _polylineManager;
      if (manager == null || path.isEmpty) return;

      await manager.deleteAll();

      await manager.create(
        mapbox.PolylineAnnotationOptions(
          geometry: mapbox.LineString(
            coordinates: [
              for (final point in path)
                mapbox.Position(point.longitude, point.latitude),
            ],
          ),
          lineColor: Colors.blueAccent.toARGB32(),
          lineWidth: 4,
          lineOpacity: 0.75,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to fetch route: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _fetchingRoute = false);
      }
    }
  }

  Future<List<LatLng>> _requestRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final uri = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?geometries=geojson&overview=full&access_token=${MapConfig.accessToken}',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Mapbox directions error (${response.statusCode})');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
    final routes = payload['routes'] as List<dynamic>? ?? const [];
    if (routes.isEmpty) {
      throw Exception('No route found');
    }

    final geometry = (routes.first as Map<String, dynamic>)['geometry']
            as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final coordinates = geometry['coordinates'] as List<dynamic>? ?? const [];

    final points = <LatLng>[];
    for (final coord in coordinates) {
      if (coord is List && coord.length >= 2) {
        final lon = coord[0];
        final lat = coord[1];
        if (lon is num && lat is num) {
          points.add(LatLng(lat.toDouble(), lon.toDouble()));
        }
      }
    }
    return points;
  }

  void _centerOnUser() {
    final location = _userLocation;
    if (location == null) return;
    _mapboxMap?.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(location.longitude, location.latitude),
        ),
        zoom: 15,
      ),
      mapbox.MapAnimationOptions(duration: 600),
    );
  }

  Future<void> _openInExternalMaps(ChargingStation station) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&travelmode=driving'
      '&destination=${station.latitude},${station.longitude}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Maps application.')),
      );
    }
  }

  void _removeFavorite(String id) {
    _favoritesService.remove(id);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedStation;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const Sidebar(),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: mapbox.MapWidget(
                key: const ValueKey('mapbox-map'),
                styleUri: mapbox.MapboxStyles.STANDARD,
                onMapCreated: _onMapCreated,
                onTapListener: _handleMapTap,
                onLongTapListener: _handleMapLongTap,
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _SearchBar(
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
            if (_locationStatus != null)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 96),
                  child: _StatusBanner(message: _locationStatus!),
                ),
              ),
            Positioned(
              bottom: 120,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_fetchingRoute) const _FloatingIndicator(),
                  if (_fetchingRoute) const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'center',
                    mini: true,
                    onPressed: _centerOnUser,
                    backgroundColor: Colors.white,
                    child:
                        const Icon(Icons.my_location, color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: selected == null
                      ? const SizedBox.shrink()
                      : _StationCard(
                          key: ValueKey(selected.id),
                          station: selected,
                          distanceLabel: _formatDistance(selected),
                          onNavigate: () => _openInExternalMaps(selected),
                          onRoute: () => _drawRouteTo(selected),
                          onDelete: () => _removeFavorite(selected.id),
                          loadingRoute: _fetchingRoute,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _formatDistance(ChargingStation station) {
    final user = _userLocation;
    if (user == null) return null;
    final meters = geo.Geolocator.distanceBetween(
      user.latitude,
      user.longitude,
      station.latitude,
      station.longitude,
    );
    if (meters < 1000) {
      return '${meters.round()} m away';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onMenuTap});

  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      elevation: 4,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.grey),
              onPressed: onMenuTap,
              tooltip: 'Menu',
            ),
            const Expanded(
              child: TextField(
                enabled: false,
                decoration: InputDecoration(
                  hintText: 'Search for a charger (coming soon)',
                  border: InputBorder.none,
                  suffixIcon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({
    super.key,
    required this.station,
    required this.onRoute,
    required this.onNavigate,
    required this.onDelete,
    required this.loadingRoute,
    this.distanceLabel,
  });

  final ChargingStation station;
  final VoidCallback onRoute;
  final VoidCallback onNavigate;
  final VoidCallback onDelete;
  final bool loadingRoute;
  final String? distanceLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      if (station.address != null &&
                          station.address!.isNotEmpty)
                        Text(
                          station.address!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.black54),
                        ),
                      if (distanceLabel != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          distanceLabel!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.blueGrey),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Lat: ${station.latitude.toStringAsFixed(5)}, '
                        'Lng: ${station.longitude.toStringAsFixed(5)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black45),
                      ),
                      if (station.notes != null && station.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            station.notes!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.black87),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove from favourites',
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: loadingRoute ? null : onRoute,
                    icon: loadingRoute
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.route),
                    label: Text(
                      loadingRoute ? 'Calculating...' : 'Route',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Maps'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(30),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingIndicator extends StatelessWidget {
  const _FloatingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _NewStationDetails {
  _NewStationDetails({
    required this.name,
    this.address,
    this.plugTypes = const <String>[],
    this.notes,
  });

  final String name;
  final String? address;
  final List<String> plugTypes;
  final String? notes;
}

class _AddStationSheet extends StatefulWidget {
  const _AddStationSheet({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  State<_AddStationSheet> createState() => _AddStationSheetState();
}

class _AddStationSheetState extends State<_AddStationSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _plugTypesController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _plugTypesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomInset + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Save charger',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Lat: ${widget.latitude.toStringAsFixed(6)}, '
              'Lng: ${widget.longitude.toStringAsFixed(6)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Station name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              textInputAction: TextInputAction.next,
              decoration:
                  const InputDecoration(labelText: 'Address (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _plugTypesController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Plug types (comma separated, optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() != true) return;
                      final plugTypes = _plugTypesController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList(growable: false);
                      Navigator.pop(
                        context,
                        _NewStationDetails(
                          name: _nameController.text.trim(),
                          address: _addressController.text.trim(),
                          plugTypes: plugTypes,
                          notes: _notesController.text.trim(),
                        ),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
