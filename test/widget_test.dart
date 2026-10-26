import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_reader/main.dart';
import 'package:nfc_reader/vault.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows an empty wallet and the default gates', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(GateKeyApp(vault: Vault(prefs)));
    await tester.pump();

    expect(find.text('No cards saved'), findsOneWidget);
    expect(find.text('Save a card'), findsOneWidget);

    await tester.tap(find.text('Gates'));
    await tester.pump();

    expect(find.text('Main gate'), findsOneWidget);
    expect(find.text('Server room'), findsOneWidget);
  });
}
