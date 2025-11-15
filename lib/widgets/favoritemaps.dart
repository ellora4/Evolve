import 'package:evolve/models/charging_station.dart';
import 'package:evolve/services/favorites_service.dart';
import 'package:flutter/material.dart';

class MapsPage extends StatelessWidget {
  const MapsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Charging Spots'),
        backgroundColor: const Color.fromARGB(255, 228, 204, 96),
        elevation: 0,
        centerTitle: true,
      ),
      body: ValueListenableBuilder<List<ChargingStation>>(
        valueListenable: FavoritesService.instance.favorites,
        builder: (context, favorites, _) {
          if (favorites.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final station = favorites[index];
              return _FavoriteTile(station: station);
            },
          );
        },
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.station});

  final ChargingStation station;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(
          station.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Lat: ${station.latitude.toStringAsFixed(5)}, Lng: ${station.longitude.toStringAsFixed(5)}',
              style: const TextStyle(color: Colors.black54),
            ),
            if (station.address != null && station.address!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  station.address!,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            if (station.notes != null && station.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  station.notes!,
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            if (station.plugTypes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: station.plugTypes
                      .map(
                        (type) => Chip(
                          label: Text(type),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: const Color(0xFFF3F5FF),
                          labelStyle: const TextStyle(
                            color: Color(0xFF1A73E8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Remove',
          onPressed: () => FavoritesService.instance.remove(station.id),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.ev_station_outlined,
                size: 48, color: Color(0xFFB0B0B0)),
            const SizedBox(height: 16),
            Text(
              'No saved charging spots yet.',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Long-press the map on the home screen to add the places you trust.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
