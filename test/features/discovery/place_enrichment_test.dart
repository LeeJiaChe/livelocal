import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/features/places/domain/external_place.dart';
import 'package:live_local/features/places/domain/place_enrichment.dart';
import 'package:live_local/features/places/presentation/external_places_screen.dart';

void main() {
  testWidgets('one Google destination renders both LiveLocal insight layers',
      (tester) async {
    const place = ExternalPlace(
      provider: 'google',
      placeId: 'ChIJUnifiedPlace123',
      name: 'Village Park Restaurant',
      formattedAddress: '5 Jalan SS 21/37, Damansara Utama, Selangor',
      latitude: 3.134,
      longitude: 101.621,
      primaryType: 'restaurant',
    );
    const enrichment = PlaceEnrichment(
      googlePlaceId: 'ChIJUnifiedPlace123',
      eat: PlaceInsightSummary(
        id: 'eat-1',
        kind: 'eat',
        name: 'Village Park Restaurant',
        reviewedDishes: 'Nasi Lemak Ayam Goreng',
      ),
      spot: PlaceInsightSummary(
        id: 'spot-1',
        kind: 'spot',
        name: 'Village Park Restaurant',
        bestTime: 'Before 10am',
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExternalPlaceCard(place: place, enrichment: enrichment),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('external-place-ChIJUnifiedPlace123')),
        findsOneWidget);
    expect(find.text('Village Park Restaurant'), findsOneWidget);
    expect(find.text('LIVELOCAL EAT'), findsOneWidget);
    expect(find.text('THINGS TO DO'), findsOneWidget);
    expect(find.textContaining('Nasi Lemak Ayam Goreng'), findsOneWidget);
  });

  test('unenriched Google identity remains a normal place', () {
    final enrichment = PlaceEnrichment.fromJson({
      'google_place_id': 'ChIJLegacyPlace123',
      'spot': null,
      'eat': null,
    });
    expect(enrichment.hasInsights, isFalse);
  });
}
