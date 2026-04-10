import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/work_entry.dart';

const _entriesKey = 'work_entries_v1';

class WorkStorage {
  Future<List<WorkEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_entriesKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => WorkEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveEntries(List<WorkEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_entriesKey, raw);
  }
}
