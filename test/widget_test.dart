import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lemakin_app/main.dart';
import 'package:lemakin_app/core/di/injection_container.dart' as di;

void main() {
  setUp(() async {
    // Reset GetIt between tests to prevent duplicate registrations
    await GetIt.instance.reset();
    // Initialize dependencies
    await di.init();
    await initializeDateFormatting('id', null);
  });

  testWidgets('Lemakin App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Advance the mock timers so that in-memory database delays resolve
    await tester.pump(const Duration(milliseconds: 1000));

    // Verify that the main app widget runs and renders
    expect(find.byType(MyApp), findsOneWidget);
  });
}
