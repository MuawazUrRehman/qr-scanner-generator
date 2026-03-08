import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryModel {
  final String code;
  final String type; // We store enum string or derived title
  final DateTime date;
  final String? customName;

  HistoryModel({
    required this.code,
    required this.type,
    required this.date,
    this.customName,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'type': type,
        'date': date.toIso8601String(),
        'customName': customName,
      };

  factory HistoryModel.fromJson(Map<String, dynamic> json) => HistoryModel(
        code: json['code'],
        type: json['type'],
        date: DateTime.parse(json['date']),
        customName: json['customName'],
      );
}

class HistoryService {
  static const String _keyHistory = 'qr_history';

  Future<List<HistoryModel>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString(_keyHistory);
    if (historyString == null) return [];

    final List<dynamic> jsonList = jsonDecode(historyString);
    return jsonList.map((json) => HistoryModel.fromJson(json)).toList();
  }

  Future<void> addToHistory(String code, String type) async {
    final prefs = await SharedPreferences.getInstance();
    List<HistoryModel> history = await getHistory();

    // Prevent duplicates (optional, based on requirement, usually good UX)
    // For now, let's allow duplicates but maybe we can check if the exact same code was scanned just now.
    // Let's add new items to the top.
    final newItem = HistoryModel(
      code: code,
      type: type,
      date: DateTime.now(),
    );

    history.insert(0, newItem); // Add to top

    // Optional: Limit history size (e.g. 100 items)
    if (history.length > 50) {
      history = history.sublist(0, 50);
    }

    final String encoded = jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_keyHistory, encoded);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHistory);
  }
  
  Future<void> deleteItem(int index) async {
      final prefs = await SharedPreferences.getInstance();
      List<HistoryModel> history = await getHistory();
      if(index >=0 && index < history.length){
          history.removeAt(index);
          final String encoded = jsonEncode(history.map((e) => e.toJson()).toList());
          await prefs.setString(_keyHistory, encoded);
      }
  }

  Future<void> updateTitle(String code, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    List<HistoryModel> history = await getHistory();
    
    // Update all occurrences of this code
    bool changed = false;
    final updatedHistory = history.map((item) {
      if (item.code == code) {
        changed = true;
        return HistoryModel(
          code: item.code,
          type: item.type,
          date: item.date,
          customName: newName,
        );
      }
      return item;
    }).toList();

    if (changed) {
      final String encoded = jsonEncode(updatedHistory.map((e) => e.toJson()).toList());
      await prefs.setString(_keyHistory, encoded);
    }
  }
}
