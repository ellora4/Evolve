import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/charging_station.dart';

class FavoritesService {
  FavoritesService._();

  static final FavoritesService instance = FavoritesService._();

  final ValueNotifier<List<ChargingStation>> favorites =
      ValueNotifier<List<ChargingStation>>(const []);

  ChargingStation? byId(String id) {
    try {
      return favorites.value.firstWhere((station) => station.id == id);
    } catch (_) {
      return null;
    }
  }

  void add(ChargingStation station) {
    final next = List<ChargingStation>.from(favorites.value);
    next.add(station);
    favorites.value = List.unmodifiable(next);
  }

  void remove(String id) {
    final next = favorites.value
        .where((station) => station.id != id)
        .toList(growable: false);
    favorites.value = List.unmodifiable(next);
  }

  String generateId() {
    final random = Random();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final salt = random.nextInt(1 << 20);
    return 'fav_${ts}_$salt';
  }
}
