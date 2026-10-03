/// A pair of two people — mirrors the future `pairs` Postgres table.
class Pairing {
  const Pairing({
    required this.id,
    required this.userA,
    required this.userB,
    required this.partnerName,
    required this.partnerEmoji,
    required this.inviteCode,
    this.status = 'active',
    required this.createdAt,
  });

  final String id;
  final String userA;
  final String userB;
  final String partnerName;
  final String partnerEmoji;
  final String inviteCode;
  final String status;
  final DateTime createdAt;

  factory Pairing.fromJson(Map<String, dynamic> json) => Pairing(
        id: json['id'] as String,
        userA: json['user_a'] as String,
        userB: json['user_b'] as String,
        partnerName: json['partner_name'] as String? ?? 'Partner',
        partnerEmoji: json['partner_emoji'] as String? ?? '💛',
        inviteCode: json['invite_code'] as String,
        status: json['status'] as String? ?? 'active',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'user_a': userA,
        'user_b': userB,
        'partner_name': partnerName,
        'partner_emoji': partnerEmoji,
        'invite_code': inviteCode,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };
}
