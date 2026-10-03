import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/couple_stats.dart';
import '../models/mood_entry.dart';
import '../models/nudge.dart';
import '../models/pairing.dart';
import '../services/backend_services.dart';
import '../services/home_widget_service.dart';
import '../services/storage_service.dart';

/// App-wide state (Riverpod Notifier).
class AppState {
  const AppState({
    required this.profile,
    required this.pair,
    required this.nudges,
    required this.locale,
    required this.themeId,
    required this.accentName,
    required this.favorites,
    required this.anniversary,
    required this.moods,
  });

  final AppUser? profile;
  final Pairing? pair;
  final List<Nudge> nudges;
  final String locale;
  final String themeId;
  final String accentName;
  final List<String> favorites;
  final DateTime? anniversary;
  final List<MoodEntry> moods;

  CoupleStats get stats => CoupleStats.from(
        profile: profile,
        pair: pair,
        nudges: nudges,
        moods: moods,
        anniversary: anniversary,
      );

  AppState copyWith({
    AppUser? profile,
    Pairing? pair,
    List<Nudge>? nudges,
    String? locale,
    String? themeId,
    String? accentName,
    List<String>? favorites,
    DateTime? anniversary,
    List<MoodEntry>? moods,
  }) =>
      AppState(
        profile: profile ?? this.profile,
        pair: pair ?? this.pair,
        nudges: nudges ?? this.nudges,
        locale: locale ?? this.locale,
        themeId: themeId ?? this.themeId,
        accentName: accentName ?? this.accentName,
        favorites: favorites ?? this.favorites,
        anniversary: anniversary ?? this.anniversary,
        moods: moods ?? this.moods,
      );
}

class AppController extends Notifier<AppState> {
  @override
  AppState build() {
    final storage = ref.read(storageProvider);
    final profile = storage.loadProfile();
    final pair = ref.read(pairServiceProvider).currentPair();
    final nudges = ref.read(nudgeServiceProvider).recentNudges();

    // Seed the home-screen widget with whatever is already stored, so the
    // card on the launcher's home screen is populated on cold start.
    unawaited(HomeWidgetService.sync(
      profile: profile,
      pair: pair,
      nudges: nudges,
    ));

    return AppState(
      profile: profile,
      pair: pair,
      nudges: nudges,
      locale: storage.locale,
      themeId: storage.theme,
      accentName: storage.accent,
      favorites: storage.loadFavorites(),
      anniversary: storage.anniversary,
      moods: storage.loadMoods(),
    );
  }

  static final Random _rng = Random();

  /// Push the current couple data onto the Android home-screen widget.
  ///
  /// Driven from the state mutations themselves rather than a widget-level
  /// `ref.listen`, because Riverpod 3 dropped `fireImmediately` from
  /// `WidgetRef.listen`. Fire-and-forget and internally guarded, so it can
  /// never block or break a state change.
  void _pushHomeWidget() {
    unawaited(HomeWidgetService.sync(
      profile: state.profile,
      pair: state.pair,
      nudges: state.nudges,
    ));
  }

  String _newId(String prefix) =>
      '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(9999)}';

  // ---- onboarding ----
  Future<void> completeOnboarding(String name, String emoji) async {
    final user = AppUser(
      id: _newId('u'),
      displayName: name.trim(),
      avatarEmoji: emoji,
      createdAt: DateTime.now(),
    );
    await ref.read(storageProvider).saveProfile(user);
    state = state.copyWith(profile: user);
    _pushHomeWidget();
  }

  Future<void> updateProfile({required String name, required String emoji}) async {
    final current = state.profile;
    if (current == null) return;
    final updated =
        current.copyWith(displayName: name.trim(), avatarEmoji: emoji);
    await ref.read(storageProvider).saveProfile(updated);
    state = state.copyWith(profile: updated);
    _pushHomeWidget();
  }

  // ---- pairing ----
  String generateInviteCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    return List<String>.generate(
      6,
      (_) => chars[_rng.nextInt(chars.length)],
    ).join();
  }

  Future<void> acceptInvite({
    required String code,
    required String partnerName,
    required String partnerEmoji,
  }) async {
    final me = state.profile;
    final pair = Pairing(
      id: _newId('p'),
      userA: me?.id ?? 'u_local',
      userB: 'u_partner',
      partnerName: partnerName.trim().isEmpty ? 'पार्टनर' : partnerName.trim(),
      partnerEmoji: partnerEmoji,
      inviteCode: code.toUpperCase(),
      createdAt: DateTime.now(),
    );
    await ref.read(pairServiceProvider).savePair(pair);
    state = state.copyWith(pair: pair);
    _pushHomeWidget();
  }

  Future<void> breakPair() async {
    await ref.read(pairServiceProvider).breakPair();
    await ref.read(nudgeServiceProvider).clearNudges();
    state = AppState(
      profile: state.profile,
      pair: null,
      nudges: <Nudge>[],
      locale: state.locale,
      themeId: state.themeId,
      accentName: state.accentName,
      favorites: state.favorites,
      anniversary: state.anniversary,
      moods: state.moods,
    );
    _pushHomeWidget();
  }

  // ---- nudges ----
  Future<void> sendNudge({required String message, required String emoji}) async {
    final nudge = Nudge(
      id: _newId('n'),
      pairId: state.pair?.id,
      senderId: state.profile?.id ?? 'u_local',
      message: message.trim(),
      theme: state.themeId,
      sound: 'soft_chime',
      createdAt: DateTime.now(),
    );
    await ref.read(nudgeServiceProvider).sendNudge(nudge);
    state = state.copyWith(nudges: [nudge, ...state.nudges]);
    _pushHomeWidget();
  }

  /// Demo: a nudge that "arrives" from the partner (Knock→FCM later).
  Future<Nudge> receiveDemoNudge({
    required String message,
    required String emoji,
  }) async {
    final nudge = Nudge(
      id: _newId('n'),
      pairId: state.pair?.id,
      senderId: 'demo_incoming',
      message: message,
      theme: state.themeId,
      sound: 'soft_chime',
      createdAt: DateTime.now(),
    );
    await ref.read(nudgeServiceProvider).sendNudge(nudge);
    state = state.copyWith(nudges: [nudge, ...state.nudges]);
    _pushHomeWidget();
    return nudge;
  }

  Future<void> markSeen(String nudgeId) async {
    await ref.read(nudgeServiceProvider).markSeen(nudgeId);
    final refreshed = ref.read(nudgeServiceProvider).recentNudges();
    state = state.copyWith(nudges: refreshed);
    _pushHomeWidget();
  }

  /// Replay an existing nudge in the overlay (long-press a recent nudge).
  Nudge? byId(String id) {
    for (final Nudge n in state.nudges) {
      if (n.id == id) return n;
    }
    return null;
  }

  // ---- mood check-in ----
  Future<void> logMood(String emoji) async {
    final entry = MoodEntry(emoji: emoji, at: DateTime.now());
    final list = <MoodEntry>[entry, ...state.moods];
    await ref.read(storageProvider).saveMoods(list);
    state = state.copyWith(moods: list);
  }

  // ---- favorites ----
  Future<void> toggleFavorite(String presetId) async {
    final favs = List<String>.from(state.favorites);
    if (favs.contains(presetId)) {
      favs.remove(presetId);
    } else {
      favs.insert(0, presetId);
    }
    await ref.read(storageProvider).saveFavorites(favs);
    state = state.copyWith(favorites: favs);
  }

  // ---- prefs ----
  Future<void> setLocale(String locale) async {
    await ref.read(storageProvider).setLocale(locale);
    state = state.copyWith(locale: locale);
  }

  Future<void> setTheme(String themeId) async {
    await ref.read(storageProvider).setTheme(themeId);
    state = state.copyWith(themeId: themeId);
  }

  Future<void> setAccent(String accentName) async {
    await ref.read(storageProvider).setAccent(accentName);
    state = state.copyWith(accentName: accentName);
  }

  Future<void> setAnniversary(DateTime? date) async {
    await ref.read(storageProvider).setAnniversary(date);
    state = state.copyWith(anniversary: date);
  }
}

final storageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError('storageProvider must be overridden in main()');
});

final nudgeServiceProvider = Provider<NudgeService>(
  (ref) => DemoNudgeService(ref.watch(storageProvider)),
);

final pairServiceProvider = Provider<PairService>(
  (ref) => DemoPairService(ref.watch(storageProvider)),
);

final appProvider =
    NotifierProvider<AppController, AppState>(AppController.new);
