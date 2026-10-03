/// A single mood check-in — mirrors future `moods` table (planned).
class MoodEntry {
  const MoodEntry({required this.emoji, required this.at});

  final String emoji;
  final DateTime at;

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
        emoji: json['emoji'] as String,
        at: DateTime.parse(json['at'] as String),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'emoji': emoji,
        'at': at.toIso8601String(),
      };
}
