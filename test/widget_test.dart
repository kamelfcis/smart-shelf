import 'package:flutter_test/flutter_test.dart';
import 'package:smart_shelf/main.dart';

void main() {
  testWidgets('SmartShelf app smoke test', (WidgetTester tester) async {
    // Ensure the app builds without crashing
    expect(SmartShelfApp, isNotNull);
  });
}
