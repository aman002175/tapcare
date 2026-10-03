import '../models/nudge.dart';
import '../models/pairing.dart';
import 'storage_service.dart';

/// Adapter interfaces for future backend wiring.
///
/// DEMO build: only `DemoNudgeService` / `DemoPairService` (local) exist.
/// Later:
///   * `SupabaseNudgeService` — Postgres insert + Realtime channel watch.
///   * `KnockPushService` — register FCM token, Knock delivers push.
///   * `RazorpayPaymentService` — ₹199 order + webhook-verified unlock.
/// Screens depend on these interfaces only, so wiring a real backend never
/// touches UI code.
abstract class NudgeService {
  List<Nudge> recentNudges();
  Future<void> sendNudge(Nudge nudge);
  Future<void> markSeen(String nudgeId);
  Future<void> clearNudges();
}

abstract class PairService {
  Pairing? currentPair();
  Future<void> savePair(Pairing pair);
  Future<void> breakPair();
}

/// Demo implementation: local storage only, no network.
class DemoNudgeService implements NudgeService {
  DemoNudgeService(this._storage);

  final LocalStorage _storage;

  @override
  List<Nudge> recentNudges() => _storage.loadNudges();

  @override
  Future<void> sendNudge(Nudge nudge) async {
    final list = _storage.loadNudges();
    list.insert(0, nudge);
    await _storage.saveNudges(list);
  }

  @override
  Future<void> markSeen(String nudgeId) async {
    final list = _storage.loadNudges();
    final idx = list.indexWhere((Nudge n) => n.id == nudgeId);
    if (idx == -1) return;
    final old = list[idx];
    list[idx] = Nudge(
      id: old.id,
      pairId: old.pairId,
      senderId: old.senderId,
      message: old.message,
      theme: old.theme,
      sound: old.sound,
      createdAt: old.createdAt,
      seenAt: DateTime.now(),
    );
    await _storage.saveNudges(list);
  }

  @override
  Future<void> clearNudges() => _storage.saveNudges(<Nudge>[]);
}

/// Demo implementation: local storage only, no network.
class DemoPairService implements PairService {
  DemoPairService(this._storage);

  final LocalStorage _storage;

  @override
  Pairing? currentPair() => _storage.loadPair();

  @override
  Future<void> savePair(Pairing pair) => _storage.savePair(pair);

  @override
  Future<void> breakPair() => _storage.clearPair();
}
