/// A single nudge — mirrors the future `nudges` Postgres table.
class Nudge {
  const Nudge({
    required this.id,
    required this.pairId,
    required this.senderId,
    required this.message,
    required this.theme,
    required this.sound,
    required this.createdAt,
    this.seenAt,
  });

  final String id;
  final String? pairId;
  final String senderId;
  final String message;
  final String theme;
  final String sound;
  final DateTime createdAt;
  final DateTime? seenAt;

  bool get seen => seenAt != null;

  factory Nudge.fromJson(Map<String, dynamic> json) => Nudge(
        id: json['id'] as String,
        pairId: json['pair_id'] as String?,
        senderId: json['sender_id'] as String,
        message: json['message'] as String,
        theme: json['theme'] as String? ?? 'peach',
        sound: json['sound'] as String? ?? 'soft_chime',
        createdAt: DateTime.parse(json['created_at'] as String),
        seenAt: json['seen_at'] == null
            ? null
            : DateTime.parse(json['seen_at'] as String),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'pair_id': pairId,
        'sender_id': senderId,
        'message': message,
        'theme': theme,
        'sound': sound,
        'created_at': createdAt.toIso8601String(),
        'seen_at': seenAt?.toIso8601String(),
      };
}
