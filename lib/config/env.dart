/// Runtime configuration for NudgeBuddy.
///
/// Real service keys belong in `.env.example` at the repo root (placeholders
/// only). This build ships in DEMO/LOCAL MODE: no backend is ever contacted.
///
/// When the owner gets real credentials, inject them at build time:
///   flutter build apk --dart-define=SUPABASE_URL=https://xxx.supabase.co ...
class Env {
  Env._();

  // ---- Future service keys (placeholders until the owner fills them) ----
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );
  static const String supabaseServiceRoleKey = String.fromEnvironment(
    'SUPABASE_SERVICE_ROLE_KEY',
    defaultValue: 'YOUR_SUPABASE_SERVICE_ROLE_KEY',
  );
  static const String knockApiKey = String.fromEnvironment(
    'KNOCK_API_KEY',
    defaultValue: 'YOUR_KNOCK_API_KEY',
  );
  static const String knockSigningKey = String.fromEnvironment(
    'KNOCK_SIGNING_KEY',
    defaultValue: 'YOUR_KNOCK_SIGNING_KEY',
  );
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'YOUR_RAZORPAY_KEY_ID',
  );
  static const String razorpayKeySecret = String.fromEnvironment(
    'RAZORPAY_KEY_SECRET',
    defaultValue: 'YOUR_RAZORPAY_KEY_SECRET',
  );

  /// True once the owner replaced the placeholders with real values.
  static bool get isConfigured =>
      !supabaseUrl.contains('YOUR_PROJECT') &&
      !supabaseAnonKey.startsWith('YOUR_');

  /// This build never calls a backend — everything is stored on-device.
  static const bool demoMode = true;
}
