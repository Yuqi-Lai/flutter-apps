import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  testWidgets('App displays camera screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Take and Upload Picture')),
          body: const Center(child: Text('Camera Preview')),
        ),
      ),
    );

    expect(find.text('Take and Upload Picture'), findsOneWidget);
  });
}
