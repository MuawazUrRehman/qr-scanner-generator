import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  // Scanner Settings
  bool _vibrate = true;
  bool _sound = true;
  bool _autoCopy = false;
  bool _openWeb = false;
  bool _batchScan = false;
  bool _addToHistory = true;

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get vibrate => _vibrate;
  bool get sound => _sound;
  bool get autoCopy => _autoCopy;
  bool get openWeb => _openWeb;
  bool get batchScan => _batchScan;
  bool get addToHistory => _addToHistory;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Theme
    final isDark = prefs.getBool('isDark') ?? false; // Default to light/system if not set, or logical logic
    // Actually, let's simpler: store theme mode as integer or string. 
    // Or just boolean for "Dark Mode" switch as requested.
    // User requested "Dark mode" toggle. So true = dark, false = light.
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    // Load Scanner Settings
    _vibrate = prefs.getBool('vibrate') ?? true;
    _sound = prefs.getBool('sound') ?? true;
    _autoCopy = prefs.getBool('autoCopy') ?? false;
    _openWeb = prefs.getBool('openWeb') ?? false;
    _batchScan = prefs.getBool('batchScan') ?? false;
    _addToHistory = prefs.getBool('addToHistory') ?? true;

    notifyListeners();
  }

  // Setters with Persistence

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDark);
  }

  Future<void> setVibrate(bool val) async {
    _vibrate = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrate', val);
  }

  Future<void> setSound(bool val) async {
    _sound = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound', val);
  }

  Future<void> setAutoCopy(bool val) async {
    _autoCopy = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoCopy', val);
  }

  Future<void> setOpenWeb(bool val) async {
    _openWeb = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('openWeb', val);
  }

  Future<void> setBatchScan(bool val) async {
    _batchScan = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('batchScan', val);
  }

  Future<void> setAddToHistory(bool val) async {
    _addToHistory = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('addToHistory', val);
  }
}
