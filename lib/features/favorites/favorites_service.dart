import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_scanner/core/services/hive_database.dart';

class FavoritesService {
  final Box _box = HiveDatabase.instance.favoritesBox;

  // Get all favorites (as Map)
  List<Map<dynamic, dynamic>> getFavorites() {
    return _box.values.map((e) => e as Map<dynamic, dynamic>).toList();
  }

  // Check if code is favorited
  bool isFavorite(String code) {
    // We can use the code as the key for O(1) access if unique,
    // or just search the values if we auto-increment keys.
    // Let's use 'code' as key if possible, but code can be duplicate/long.
    // Better to scan values or use a secondary index.
    // Given the scale, scanning values is fine, or storing as {code: {data}} map.
    // Let's store key as 'code'.
    return _box.containsKey(code);
  }

  Future<void> toggleFavorite(String code, String type) async {
    if (_box.containsKey(code)) {
      await _box.delete(code);
    } else {
      await _box.put(code, {
        'code': code,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
        // customName might be missing if toggled new. Can be added later.
      });
    }
  }

  Future<void> updateTitle(String code, String newName) async {
    if (_box.containsKey(code)) {
      final item = _box.get(code) as Map;
      final updatedItem = Map<String, dynamic>.from(item);
      updatedItem['customName'] = newName; // or 'title'
      await _box.put(code, updatedItem);
    }
  }

  String? getTitle(String code) {
    if (_box.containsKey(code)) {
      final item = _box.get(code) as Map;
      return item['customName'] as String?;
    }
    return null;
  }

  Future<void> clearAllFavorites() async {
    await _box.clear();
  }

  ValueListenable<Box> listenable() {
    return _box.listenable();
  }
}
