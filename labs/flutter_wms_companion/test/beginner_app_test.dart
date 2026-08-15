import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/beginner_main.dart';

void main() {
  testWidgets('counter supports add, add five, and clear', (tester) async {
    await tester.pumpWidget(const WarehouseCounterApp());

    expect(find.text('0 รายการ'), findsOneWidget);
    expect(
      tester.widget<TextButton>(find.byKey(const Key('clear-count'))).onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('add-one')));
    await tester.pump();
    expect(find.text('1 รายการ'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-five')));
    await tester.pump();
    expect(find.text('6 รายการ'), findsOneWidget);

    await tester.tap(find.byKey(const Key('clear-count')));
    await tester.pump();
    expect(find.text('0 รายการ'), findsOneWidget);
  });
}
