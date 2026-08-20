import 'package:flutter_test/flutter_test.dart';

// Helper simulating the safe _signedImage logic implemented across repositories
Future<String> resolveImage(
  String? path,
  Future<String> Function(String storagePath) storageSigner,
) async {
  if (path == null || path.trim().isEmpty) return '';
  final trimmed = path.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri != null &&
      uri.hasScheme &&
      (uri.scheme == 'http' || uri.scheme == 'https')) {
    return trimmed;
  }
  try {
    return await storageSigner(trimmed);
  } catch (_) {
    return '';
  }
}

void main() {
  group('Safe Image Resolver and Failure Isolation', () {
    test('absolute HTTPS image URL returns unchanged without calling storage',
        () async {
      var storageCalled = false;
      final result = await resolveImage(
        'https://images.unsplash.com/photo-1596422846543-75c6fc197f07',
        (path) async {
          storageCalled = true;
          return 'signed/$path';
        },
      );

      expect(
        result,
        'https://images.unsplash.com/photo-1596422846543-75c6fc197f07',
      );
      expect(storageCalled, isFalse);
    });

    test('absolute HTTP image URL returns unchanged without calling storage',
        () async {
      var storageCalled = false;
      final result = await resolveImage(
        'http://example.com/photo.jpg',
        (path) async {
          storageCalled = true;
          return 'signed/$path';
        },
      );

      expect(result, 'http://example.com/photo.jpg');
      expect(storageCalled, isFalse);
    });

    test(
        'null or empty image path returns empty string without calling storage',
        () async {
      var storageCalled = false;
      final nullResult = await resolveImage(null, (path) async {
        storageCalled = true;
        return 'signed/$path';
      });
      final emptyResult = await resolveImage('   ', (path) async {
        storageCalled = true;
        return 'signed/$path';
      });

      expect(nullResult, '');
      expect(emptyResult, '');
      expect(storageCalled, isFalse);
    });

    test('storage object path calls createSignedUrl', () async {
      final result = await resolveImage(
        'spots/user1/image_123.jpg',
        (path) async => 'https://storage.supabase.co/signed/$path?token=xyz',
      );

      expect(
        result,
        'https://storage.supabase.co/signed/spots/user1/image_123.jpg?token=xyz',
      );
    });

    test(
        'one broken image / storage exception degrades to empty string and does not destroy the list',
        () async {
      final rows = [
        {
          'id': '1',
          'name': 'Spot 1',
          'image': 'https://images.unsplash.com/p1'
        },
        {'id': '2', 'name': 'Spot 2', 'image': 'broken_storage_path.jpg'},
        {'id': '3', 'name': 'Spot 3', 'image': 'valid_storage_path.jpg'},
        {'id': '4', 'name': 'Spot 4', 'image': null},
      ];

      final resolvedList = await Future.wait(
        rows.map((row) async {
          final resolvedImage = await resolveImage(
            row['image'],
            (storagePath) async {
              if (storagePath == 'broken_storage_path.jpg') {
                throw Exception('Storage object not found');
              }
              return 'https://storage.supabase.co/signed/$storagePath';
            },
          );
          return {
            'id': row['id'],
            'name': row['name'],
            'image': resolvedImage,
          };
        }),
      );

      expect(resolvedList.length, 4);
      expect(resolvedList[0]['image'], 'https://images.unsplash.com/p1');
      expect(resolvedList[1]['image'], ''); // isolated failure
      expect(
        resolvedList[2]['image'],
        'https://storage.supabase.co/signed/valid_storage_path.jpg',
      );
      expect(resolvedList[3]['image'], '');
    });
  });
}
