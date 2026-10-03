import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/mood_entry.dart';
import '../models/nudge.dart';
import '../models/pairing.dart';

/// Local demo storage — everything lives on-device (shared_preferences).
///
/// This is the DEMO-ONLY data layer. When Supabase keys arrive, implement
/// `SupabaseStorage` with the same methods and swap it in `main.dart`;
/// screens/state do not change.
class LocalStorage {
  LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String _kProfile = 'profile_json';
  static const String _kPair = 'pair_json';
  static const String _kNudges = 'nudges_json';
  static const String _kLocale = 'locale';
  static const String _kTheme = 'theme';
  static const String _kFavorites = 'favorites_json';
  static const String _kAccent = 'accent';
  static const String _kAnniversary = 'anniversary';
  static const String _kMoods = 'moods_json';

  /// Recent nudges are capped (spec: last 20 per pair).
  static const int maxNudges = 20;

  // ---- profile ----
  AppUser? loadProfile() {
    final raw = _prefs.getString(_kProfile);
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<bool> saveProfile(AppUser user) =>
      _prefs.setString(_kProfile, jsonEncode(user.toJson()));

  // ---- pair ----
  Pairing? loadPair() {
    final raw = _prefs.getString(_kPair);
    if (raw == null) return null;
    return Pairing.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<bool> savePair(Pairing pair) =>
      _prefs.setString(_kPair, jsonEncode(pair.toJson()));

  Future<bool> clearPair() => _prefs.remove(_kPair);

  // ---- nudges (newest first, capped at maxNudges) ----
  List<Nudge> loadNudges() {
    final raw = _prefs.getString(_kNudges);
    if (raw == null) return <Nudge>[];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((dynamic e) => Nudge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> saveNudges(List<Nudge> nudges) {
    final capped = nudges.length > maxNudges
        ? nudges.sublist(0, maxNudges)
        : nudges;
    return _prefs.setString(
      _kNudges,
      jsonEncode(capped.map((Nudge n) => n.toJson()).toList()),
    );
  }

  // ---- moods (last 30) ----
  List<MoodEntry> loadMoods() {
    final raw = _prefs.getString(_kMoods);
    if (raw == null) return <MoodEntry>[];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((dynamic e) => MoodEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> saveMoods(List<MoodEntry> moods) {
    final capped = moods.length > 30 ? moods.sublist(0, 30) : moods;
    return _prefs.setString(
      _kMoods,
      jsonEncode(capped.map((MoodEntry m) => m.toJson()).toList()),
    );
  }

  // ---- favorites (pinned presets) ----
  List<String> loadFavorites() {
    final raw = _prefs.getString(_kFavorites);
    if (raw == null) return <String>[];
    return (jsonDecode(raw) as List<dynamic>).cast<String>();
  }

  Future<bool> saveFavorites(List<String> ids) =>
      _prefs.setString(_kFavorites, jsonEncode(ids));

  // ---- prefs (locale / theme / accent / anniversary) ----
  String? loadString(String key) => _prefs.getString(key);

  Future<bool> saveString(String key, String value) =>
      _prefs.setString(key, value);

  String get locale => loadString(_kLocale) ?? 'hi';
  Future<bool> setLocale(String v) => saveString(_kLocale, v);

  String get theme => loadString(_kTheme) ?? 'peach';
  Future<bool> setTheme(String v) => saveString(_kTheme, v);

  String get accent => loadString(_kAccent) ?? 'Blush';
  Future<bool> setAccent(String v) => saveString(_kAccent, v);

  DateTime? get anniversary {
    final raw = loadString(_kAnniversary);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<bool> setAnniversary(DateTime? v) => v == null
      ? _prefs.remove(_kAnniversary)
      : _prefs.setString(_kAnniversary, v.toIso8601String());
}
