import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static String weight(double grams) {
    if (grams >= 1000) {
      return '${(grams / 1000).toStringAsFixed(2)} kg';
    }
    return '${grams.toStringAsFixed(1)} g';
  }

  static String quantity(int qty) {
    if (qty <= 0) return '0 units';
    if (qty == 1) return '1 unit';
    return '$qty units';
  }

  static String dateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  static String fullDate(DateTime dt) =>
      DateFormat('MMM d, yyyy • h:mm a').format(dt);

  static String chartDate(DateTime dt) => DateFormat('MMM d').format(dt);

  static String chartTime(DateTime dt) => DateFormat('HH:mm').format(dt);

  static String sensorId(String id) {
    if (id.length > 12) return '${id.substring(0, 12)}…';
    return id;
  }

  static String stockPercentage(int current, int max) {
    if (max <= 0) return '0%';
    final pct = ((current / max) * 100).clamp(0, 100).round();
    return '$pct%';
  }
}
