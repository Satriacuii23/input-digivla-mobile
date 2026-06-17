import 'package:flutter_test/flutter_test.dart';

import 'package:digivla_mobile/main.dart';

void main() {
  testWidgets('App loads login screen', (tester) async {
    await tester.pumpWidget(const DigivlaApp());
    await tester.pumpAndSettle();
    expect(find.text('Masuk'), findsOneWidget);
  });
}
