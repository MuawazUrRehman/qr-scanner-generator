import 'package:hive_flutter/hive_flutter.dart';

class HiveDatabase {
  // Singleton instance
  static final HiveDatabase _instance = HiveDatabase._internal();
  static HiveDatabase get instance => _instance;

  // Box names
  static const String _batchBoxName = 'batch_scans';
  static const String _favoritesBoxName = 'favorites';
  static const String _settingsBoxName = 'settings';

  HiveDatabase._internal();

  /// Initialize Hive and open all necessary boxes
  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_batchBoxName);
    await Hive.openBox(_favoritesBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  /// Get the Batch Scans box
  Box get batchBox => Hive.box(_batchBoxName);

  /// Get the Favorites box
  Box get favoritesBox => Hive.box(_favoritesBoxName);

  /// Get the Settings box
  Box get settingsBox => Hive.box(_settingsBoxName);

  /// Close Hive
  Future<void> close() async {
    await Hive.close();
  }
}
