/// Local profile — mirrors the future `users` Postgres table 1:1.
class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.avatarEmoji,
    this.premiumUnlocked = false,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String avatarEmoji;
  final bool premiumUnlocked;
  final DateTime createdAt;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        displayName: json['display_name'] as String,
        avatarEmoji: json['avatar_emoji'] as String,
        premiumUnlocked: json['premium_unlocked'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'display_name': displayName,
        'avatar_emoji': avatarEmoji,
        'premium_unlocked': premiumUnlocked,
        'created_at': createdAt.toIso8601String(),
      };

  AppUser copyWith({String? displayName, String? avatarEmoji}) => AppUser(
        id: id,
        displayName: displayName ?? this.displayName,
        avatarEmoji: avatarEmoji ?? this.avatarEmoji,
        premiumUnlocked: premiumUnlocked,
        createdAt: createdAt,
      );
}
