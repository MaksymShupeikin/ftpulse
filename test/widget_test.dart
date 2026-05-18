import 'package:flutter_test/flutter_test.dart';
import 'package:ftpulse/core/imports.dart';
import 'package:ftpulse/main.dart';

void main() {
  testWidgets('shows empty connections state', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ConnectionsProvider(initialConnections: const []),
        child: const FTPulse(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Connections'), findsOneWidget);
    expect(find.text('No Connections'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
