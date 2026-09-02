import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/core/localization/app_localizations.dart';

void main() {
  group('AppLocalizations', () {
    const english = AppLocalizations(Locale('en'));
    const malay = AppLocalizations(Locale('ms'));

    test('English source copy passes through unchanged', () {
      expect(english.translate('Creator Studio'), 'Creator Studio');
    });

    test('core role and workflow copy has natural BM translations', () {
      expect(malay.translate('Creator Studio'), 'Studio Pencipta');
      expect(malay.translate('Review Queue'), 'Barisan semakan');
      expect(malay.translate('Needs changes'), 'Perlu perubahan');
      expect(
        malay.translate('Review photos'),
        isNot(equals('Review photos')),
      );
      expect(malay.translate('Overview'), 'Ringkasan');
      expect(malay.translate('Queue'), 'Barisan');
      expect(malay.translate('Trips'), 'Perjalanan');
      expect(
        malay.translate('Items that need an admin decision'),
        'Perkara yang memerlukan keputusan admin',
      );
      expect(
        malay.translate('Drafts (12)'),
        'Draf (12)',
      );
      expect(
        malay.translate('Manage LiveLocal neighbourhood guides'),
        'Urus panduan kawasan kejiranan LiveLocal',
      );
      expect(malay.translate('Post anonymously'), 'Siarkan secara tanpa nama');
      expect(
        malay.translate('Hide my name from other LiveLocal users.'),
        'Sembunyikan nama saya daripada pengguna LiveLocal yang lain.',
      );
      expect(malay.translate('Anonymous'), 'Tanpa Nama');
      expect(malay.translate('Your review'), 'Ulasan anda');
      expect(malay.translate('Block this reviewer'), 'Sekat pengulas ini');
      expect(malay.translate('Anonymous reviewer'), 'Pengulas tanpa nama');
      expect(malay.translate('Reviewer blocked.'), 'Pengulas telah disekat.');
      expect(
        malay.translate(
            'Reviewer blocked. Their public content is hidden for you.'),
        'Pengulas telah disekat. Kandungan awam mereka disembunyikan untuk anda.',
      );
    });

    test('dynamic product copy is localized without altering values', () {
      expect(malay.translate('4 approved places'), '4 tempat yang diluluskan');
      expect(malay.translate('5 stars'), '5 bintang');
      expect(malay.translate('Copy LOCAL10'), 'Salin LOCAL10');
      expect(malay.translate('3h ago'), '3 jam lalu');
      expect(
        malay.translate('Enter at least 20 characters.'),
        'Masukkan sekurang-kurangnya 20 aksara.',
      );
      expect(
        malay.translate('Enter Full address (at least 5 characters).'),
        'Masukkan Alamat penuh (sekurang-kurangnya 5 aksara).',
      );
      expect(
        malay.translate('Use a matching instagram.com HTTPS URL.'),
        'Gunakan URL HTTPS instagram.com yang sepadan.',
      );
      expect(malay.translate('Places'), 'Tempat');
      expect(malay.translate('Near me'), 'Berdekatan saya');
      expect(
        malay.translate('Load more places'),
        'Muatkan lebih banyak tempat',
      );
      expect(
        malay.translate('Generate details with AI'),
        'Jana butiran dengan AI',
      );
      expect(malay.translate('Open now'), 'Dibuka sekarang');
      expect(malay.translate('Google rating'), 'penilaian Google');
      expect(malay.translate('Visit website'), 'Lawati laman web');
    });

    test('legacy long-form role screens have genuine BM copy', () {
      expect(
        malay.translate(
          'Community travel guides are reviewed by LiveLocal before becoming public. Once approved, your itinerary will be visible to all travellers.',
        ),
        contains('Panduan perjalanan komuniti'),
      );
      expect(
        malay.translate(
          'Your restaurant submission has been sent for moderation. Once approved by an administrator, it will appear in Local Eats.',
        ),
        contains('Sumbangan restoran anda'),
      );
      expect(
        malay.translate(
          'Your account will be disabled now and scheduled for permanent deletion after 14 days. You can recover your account during this grace period by signing in and confirming recovery.',
        ),
        contains('Akaun anda akan dinyahaktifkan'),
      );
    });

    test('proper names and unknown user content remain unchanged', () {
      expect(malay.translate('Pasar Siti Khadijah'), 'Pasar Siti Khadijah');
      expect(malay.translate('Alex Eats'), 'Alex Eats');
      expect(malay.translate('TikTok'), 'TikTok');
    });

    test('never fabricates prefixed Malay copy', () {
      expect(malay.translate('Unregistered sentence'), 'Unregistered sentence');
      expect(
          malay.translate('Unregistered sentence'), isNot(contains('[Malay]')));
    });
  });
}
