import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/features/reviews/presentation/widgets/review_text_widget.dart';

void main() {
  group('ReviewTextWidget Tests', () {
    testWidgets('renders language chips and original EN review text',
        (tester) async {
      const originalText = 'Incredible hidden gem with authentic local dishes.';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReviewTextWidget(text: originalText),
          ),
        ),
      );

      // Verify language options render
      expect(find.text('EN'), findsOneWidget);
      expect(find.text('ZH'), findsOneWidget);
      expect(find.text('MS'), findsOneWidget);

      // Verify original text renders exactly once
      expect(find.text(originalText), findsOneWidget);
    });

    testWidgets(
        'selecting ZH or MS shows honest unavailable message without fake prefix',
        (tester) async {
      const originalText = 'Great coffee and cozy atmosphere.';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReviewTextWidget(text: originalText),
          ),
        ),
      );

      // Switch to Chinese
      await tester.tap(find.text('ZH'));
      await tester.pumpAndSettle();

      // Ensure no fake prefix or pseudo-translation is generated
      expect(find.textContaining('【中文】'), findsNothing);
      expect(
        find.text(
            'Translation (ZH) is not available for this review in this build.'),
        findsOneWidget,
      );

      // Switch to Malay
      await tester.tap(find.text('MS'));
      await tester.pumpAndSettle();

      // Ensure no fake prefix
      expect(find.textContaining('[Malay]'), findsNothing);
      expect(
        find.text(
            'Translation (MS) is not available for this review in this build.'),
        findsOneWidget,
      );

      // Switch back to EN
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();

      expect(find.text(originalText), findsOneWidget);
    });
  });
}
