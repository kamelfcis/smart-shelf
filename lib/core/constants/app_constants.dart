class AppConstants {
  AppConstants._();

  static const String appName = 'Smart Shelf';
  static const String supabaseUrl = 'https://njrflpglzlbyumeyizgm.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qcmZscGdsemxieXVtZXlpemdtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0Nzg4NzQsImV4cCI6MjA5MzA1NDg3NH0.idG964OiTTQ7zltdrSow6BDPMd8zUMQX7BjGXfH-H0w';

  // SharedPreferences keys
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String keyThemeMode = 'theme_mode';

  // Sensor thresholds
  static const double weightDropThresholdG = 10.0;
  static const int sensorOfflineMinutes = 5;

  // Realtime channels
  static const String channelItems = 'public:items';
  static const String channelNotifications = 'public:notifications';
  static const String channelShelves = 'public:shelves';

  // Storage buckets
  static const String bucketItemImages = 'item-images';
  static const String bucketAvatars = 'avatars';

  // Pagination
  static const int pageSize = 20;
  static const int logPageSize = 50;
}
