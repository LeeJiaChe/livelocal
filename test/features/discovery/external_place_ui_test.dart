import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/features/places/domain/external_place.dart';
import 'package:live_local/features/places/domain/place_provider.dart';
import 'package:live_local/features/places/presentation/external_places_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('external place card opens a usable provider detail',
      (tester) async {
    const place = ExternalPlace(
      provider: 'google',
      placeId: 'google-place-123',
      name: 'Penang State Museum',
      formattedAddress: 'George Town, Penang, Malaysia',
      latitude: 5.418,
      longitude: 100.337,
      rating: 4.4,
      userRatingCount: 800,
      openNow: true,
      googleMapsUri: 'https://maps.google.com/?cid=123',
    );
    await tester.pumpWidget(
      Provider<PlaceProvider>.value(
        value: const _DetailProvider(place),
        child: const MaterialApp(
          home: Scaffold(body: ExternalPlaceCard(place: place)),
        ),
      ),
    );

    expect(find.text('Google Places'), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey('external-place-google-place-123')));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Add to Trip'), findsOneWidget);
    expect(find.text('Open directions in Maps'), findsOneWidget);
    expect(
      find.textContaining('LiveLocal reviews are shown only'),
      findsOneWidget,
    );
  });

  testWidgets(
      'external detail failure keeps search data and core actions usable',
      (tester) async {
    const place = ExternalPlace(
      provider: 'google',
      placeId: 'google-place-offline',
      name: 'Melaka Riverside Cafe',
      formattedAddress: 'Melaka, Malaysia',
      latitude: 2.1944,
      longitude: 102.2491,
      googleMapsUri: 'https://maps.google.com/?cid=456',
    );
    await tester.pumpWidget(
      Provider<PlaceProvider>.value(
        value: const _FailingDetailProvider(),
        child: const MaterialApp(
          home: ExternalPlaceDetailScreen(initialPlace: place),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Live place details are unavailable'), findsOneWidget);
    expect(find.text('Melaka Riverside Cafe'), findsWidgets);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Add to Trip'), findsOneWidget);
    expect(find.text('Open directions in Maps'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}

class _DetailProvider implements PlaceProvider {
  const _DetailProvider(this.place);
  final ExternalPlace place;

  @override
  Future<ExternalPlace> details(String placeId) async => place;

  @override
  Future<List<ExternalPlace>> nearby({
    required double latitude,
    required double longitude,
    double radius = 5000,
    String? category,
    bool rankByDistance = false,
  }) =>
      throw UnimplementedError();

  @override
  Future<ExternalPlacePage> search({
    required String query,
    String? category,
    String? pageToken,
  }) =>
      throw UnimplementedError();
}

class _FailingDetailProvider implements PlaceProvider {
  const _FailingDetailProvider();

  @override
  Future<ExternalPlace> details(String placeId) =>
      Future<ExternalPlace>.error(Exception('provider unavailable'));

  @override
  Future<List<ExternalPlace>> nearby({
    required double latitude,
    required double longitude,
    double radius = 5000,
    String? category,
    bool rankByDistance = false,
  }) =>
      throw UnimplementedError();

  @override
  Future<ExternalPlacePage> search({
    required String query,
    String? category,
    String? pageToken,
  }) =>
      throw UnimplementedError();
}
