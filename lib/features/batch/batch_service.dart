import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_scanner/core/services/hive_database.dart';

class BatchService {
  final Box _box = HiveDatabase.instance.batchBox;

  List<Map<dynamic, dynamic>> getBatchedItems() {
    return _box.values.map((e) => e as Map<dynamic, dynamic>).toList();
  }

  int get count => _box.length;

  Future<void> addScan(String code, String type) async {
    await _box.add({
      'code': code,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  bool contains(String code) {
    // Check if any value has this code
    return _box.values.any((item) => (item as Map)['code'] == code);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  Future<void> deleteAt(int index) async {
    await _box.deleteAt(index);
  }

  // ValueListenable for UI updates
  ValueListenable<Box> listenable() {
    return _box.listenable();
  }
}
