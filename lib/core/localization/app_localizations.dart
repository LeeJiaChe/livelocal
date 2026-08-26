import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleController with ChangeNotifier {
  static const _preferenceKey = 'app_locale';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  bool get isMalay => _locale.languageCode == 'ms';

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_preferenceKey);
    if (saved != 'en' && saved != 'ms') return;
    _locale = Locale(saved!);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'ms') return;
    if (_locale.languageCode == languageCode) return;
    _locale = Locale(languageCode);
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, languageCode);
  }
}

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[Locale('en'), Locale('ms')];

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      const AppLocalizations(Locale('en'));

  bool get isMalay => locale.languageCode == 'ms';

  String translate(String source) {
    if (!isMalay || source.trim().isEmpty) return source;
    final exact = _ms[source];
    if (exact != null) return exact;
    return _translatePattern(source);
  }

  String _translatePattern(String source) {
    final replacements = <(RegExp, String Function(Match))>[
      (
        RegExp(r'^(.+) \((\d+)\)$'),
        (match) => '${translate(match[1]!)} (${match[2]})',
      ),
      (
        RegExp(r'^(\d+) pending moderation$'),
        (match) => '${match[1]} menunggu penyederhanaan',
      ),
      (
        RegExp(r'^(\d+) pending review$'),
        (match) => '${match[1]} menunggu semakan',
      ),
      (
        RegExp(r'^(\d+) awaiting resolution$'),
        (match) => '${match[1]} menunggu penyelesaian',
      ),
      (
        RegExp(r'^Appeal status: (.+)$', dotAll: true),
        (match) => 'Status rayuan: ${match[1]}',
      ),
      (
        RegExp(r'^Updated (.+)$'),
        (match) => 'Dikemas kini ${match[1]}',
      ),
      (
        RegExp(r'^Restriction ends: (.+)$'),
        (match) => 'Sekatan tamat: ${match[1]}',
      ),
      (
        RegExp(r'^Deletion scheduled: (.+)$'),
        (match) => 'Pemadaman dijadualkan: ${match[1]}',
      ),
      (
        RegExp(r'^Welcome back, (.+)$'),
        (match) => 'Selamat kembali, ${match[1]}',
      ),
      (
        RegExp(r'^(\d+) approved places$'),
        (match) => '${match[1]} tempat yang diluluskan',
      ),
      (
        RegExp(r'^(\d+) restaurants$'),
        (match) => '${match[1]} restoran',
      ),
      (
        RegExp(r'^(\d+) routes$'),
        (match) => '${match[1]} laluan',
      ),
      (
        RegExp(r'^(\d+) saved places · (\d+) trips$'),
        (match) => '${match[1]} tempat disimpan · ${match[2]} perjalanan',
      ),
      (
        RegExp(r'^(\d+) total$'),
        (match) => '${match[1]} jumlah',
      ),
      (
        RegExp(r'^(\d+) stars$'),
        (match) => '${match[1]} bintang',
      ),
      (
        RegExp(r'^Copy (.+)$'),
        (match) => 'Salin ${match[1]}',
      ),
      (
        RegExp(r'^(\d+) review photos$'),
        (match) => '${match[1]} foto ulasan',
      ),
      (
        RegExp(r'^(\d+)d ago$'),
        (match) => '${match[1]} hari lalu',
      ),
      (
        RegExp(r'^(\d+)h ago$'),
        (match) => '${match[1]} jam lalu',
      ),
      (
        RegExp(r'^(\d+)m ago$'),
        (match) => '${match[1]} minit lalu',
      ),
      (
        RegExp(r'^Enter at least (\d+) characters\.$'),
        (match) => 'Masukkan sekurang-kurangnya ${match[1]} aksara.',
      ),
      (
        RegExp(r'^Enter (.+) \(at least (\d+) characters\)\.$'),
        (match) =>
            'Masukkan ${translate(match[1]!)} (sekurang-kurangnya ${match[2]} aksara).',
      ),
      (
        RegExp(r'^(.+) cannot exceed (\d+) characters\.$'),
        (match) =>
            '${translate(match[1]!)} tidak boleh melebihi ${match[2]} aksara.',
      ),
      (
        RegExp(r'^Use a matching (.+) HTTPS URL\.$'),
        (match) => 'Gunakan URL HTTPS ${match[1]} yang sepadan.',
      ),
    ];
    for (final (pattern, replacement) in replacements) {
      final match = pattern.firstMatch(source);
      if (match != null) return replacement(match);
    }
    // Proper names, user content, platform names, identifiers, dates and
    // backend-provided values intentionally remain unchanged.
    return source;
  }

  static const _ms = <String, String>{
    'Home': 'Utama',
    'Explore': 'Teroka',
    'Guides': 'Panduan',
    'Saved': 'Disimpan',
    'Trips': 'Perjalanan',
    'Studio': 'Studio',
    'Profile': 'Profil',
    'Overview': 'Ringkasan',
    'Queue': 'Barisan',
    'Review Queue': 'Barisan semakan',
    'Content': 'Kandungan',
    'Users': 'Pengguna',
    'More': 'Lagi',
    'Notifications': 'Pemberitahuan',
    'No notifications': 'Tiada pemberitahuan',
    'Mark all as read': 'Tandakan semua sebagai dibaca',
    'LiveLocal': 'LiveLocal',
    'Discover Malaysia like a local': 'Terokai Malaysia seperti orang tempatan',
    'Explore authentic heritage, nature, and cultural places recommended by local communities.':
        'Terokai warisan, alam semula jadi dan tempat budaya yang disyorkan oleh komuniti tempatan.',
    'Explore travel guides': 'Terokai panduan perjalanan',
    'Community routes and itineraries shared by travellers and LiveLocal Creators.':
        'Laluan dan itinerari komuniti yang dikongsi oleh pengembara dan Pencipta LiveLocal.',
    'Search places, heritage, or towns': 'Cari tempat, warisan atau bandar',
    'Search guides or neighbourhoods': 'Cari panduan atau kawasan kejiranan',
    'Clear search': 'Kosongkan carian',
    'State or territory': 'Negeri atau wilayah',
    'Select state or territory': 'Pilih negeri atau wilayah',
    'All': 'Semua',
    'Spots': 'Tempat',
    'Eats': 'Makan',
    'Restaurants': 'Restoran',
    'LocalEats': 'Makan Lokal',
    'Sign in': 'Log masuk',
    'Sign out': 'Log keluar',
    'Create account': 'Cipta akaun',
    'Welcome back': 'Selamat kembali',
    'Log in to continue exploring': 'Log masuk untuk terus meneroka',
    'Email': 'E-mel',
    'Password': 'Kata laluan',
    'Current password': 'Kata laluan semasa',
    'Forgot password?': 'Lupa kata laluan?',
    'Try again': 'Cuba lagi',
    'Retry': 'Cuba semula',
    'Cancel': 'Batal',
    'Close': 'Tutup',
    'Save': 'Simpan',
    'Delete': 'Padam',
    'Edit': 'Sunting',
    'Submit': 'Hantar',
    'Continue': 'Teruskan',
    'Back': 'Kembali',
    'Done': 'Selesai',
    'Refresh': 'Muat semula',
    'Loading': 'Sedang dimuatkan',
    'No results found': 'Tiada hasil ditemui',
    'Something went wrong': 'Sesuatu tidak kena',
    'Something went wrong. Please try again.':
        'Sesuatu tidak kena. Sila cuba lagi.',
    'Check your connection and try again.':
        'Semak sambungan anda dan cuba lagi.',
    'We could not check your account': 'Kami tidak dapat menyemak akaun anda',
    'Checking your session': 'Sedang menyemak sesi anda',
    'Verify your email': 'Sahkan e-mel anda',
    'Check your inbox': 'Semak peti masuk anda',
    'Resend email': 'Hantar semula e-mel',
    'Verification email sent.': 'E-mel pengesahan telah dihantar.',
    'Use a different account': 'Gunakan akaun lain',
    'Account status': 'Status akaun',
    'Account temporarily restricted': 'Akaun disekat buat sementara waktu',
    'Account deletion scheduled': 'Pemadaman akaun telah dijadualkan',
    'Account unavailable': 'Akaun tidak tersedia',
    'Recover my account': 'Pulihkan akaun saya',
    'Submit an appeal': 'Hantar rayuan',
    'Appeal under review': 'Rayuan sedang disemak',
    'Recover this account?': 'Pulihkan akaun ini?',
    'Not now': 'Bukan sekarang',
    'Confirm recovery': 'Sahkan pemulihan',
    'Appeal this decision': 'Rayu keputusan ini',
    'Reason': 'Sebab',
    'Optional explanation': 'Penjelasan pilihan',
    'Submit appeal': 'Hantar rayuan',
    'Submitted': 'Dihantar',
    'Under review': 'Sedang disemak',
    'Accepted': 'Diterima',
    'Not accepted': 'Tidak diterima',
    'Withdrawn': 'Ditarik balik',
    'Draft': 'Draf',
    'Pending': 'Menunggu',
    'Approved': 'Diluluskan',
    'Published': 'Diterbitkan',
    'Rejected': 'Ditolak',
    'Needs changes': 'Perlu perubahan',
    'Expired': 'Tamat tempoh',
    'Paused': 'Dijeda',
    'Active': 'Aktif',
    'Admin Workspace': 'Ruang Kerja Admin',
    'Admin Center': 'Pusat Admin',
    'Platform operations and safety': 'Operasi dan keselamatan platform',
    'Needs review': 'Perlu disemak',
    'Published content': 'Kandungan diterbitkan',
    'Live listings': 'Penyenaraian aktif',
    'Total users': 'Jumlah pengguna',
    'Restricted': 'Disekat',
    'Action items': 'Tindakan diperlukan',
    'Items that need an admin decision':
        'Perkara yang memerlukan keputusan admin',
    'Submissions': 'Sumbangan',
    'Appeals': 'Rayuan',
    'Creators': 'Pencipta',
    'Drafts': 'Draf',
    'Check new local-place submissions before publication.':
        'Semak sumbangan tempat tempatan baharu sebelum diterbitkan.',
    'Verify business details and creator source evidence.':
        'Sahkan butiran perniagaan dan bukti sumber Pencipta.',
    'Review submitted routes and stops before publication.':
        'Semak laluan dan hentian yang dihantar sebelum diterbitkan.',
    'Review applications for Creator access.':
        'Semak permohonan untuk akses Pencipta.',
    'Review content cases reported by LiveLocal users.':
        'Semak kes kandungan yang dilaporkan oleh pengguna LiveLocal.',
    'Review appeals against account restrictions.':
        'Semak rayuan terhadap sekatan akaun.',
    'Submissions, reports, and appeals awaiting review':
        'Sumbangan, laporan dan rayuan yang menunggu semakan',
    'All caught up': 'Semua telah diselesaikan',
    'No items currently require administrator moderation or review.':
        'Tiada perkara yang memerlukan penyederhanaan atau semakan admin pada masa ini.',
    'Spot submissions': 'Sumbangan tempat',
    'Restaurant submissions': 'Sumbangan restoran',
    'Guide submissions': 'Sumbangan panduan',
    'Creator applications': 'Permohonan Pencipta',
    'Content reports': 'Laporan kandungan',
    'Account appeals': 'Rayuan akaun',
    'Quick Actions': 'Tindakan pantas',
    'Common administrative operations':
        'Operasi pentadbiran yang kerap digunakan',
    'Create guide draft': 'Cipta draf panduan',
    'Manage users': 'Urus pengguna',
    'Recent Activity': 'Aktiviti terkini',
    'Administrative decisions and system events':
        'Keputusan pentadbiran dan peristiwa sistem',
    'View all': 'Lihat semua',
    'No recent audit events recorded.':
        'Tiada peristiwa audit terkini direkodkan.',
    'Access Denied': 'Akses ditolak',
    'Administrator permission is required.': 'Kebenaran pentadbir diperlukan.',
    'Your account is not authorized to view the admin operations workspace.':
        'Akaun anda tidak dibenarkan melihat ruang kerja operasi admin.',
    'Refresh all': 'Muat semula semua',
    'Admin account': 'Akaun admin',
    'Administrator': 'Pentadbir',
    'Review': 'Semakan',
    'Audit': 'Audit',
    'Audit History': 'Sejarah audit',
    'Guide Management': 'Pengurusan panduan',
    'User Management': 'Pengurusan pengguna',
    'My Submissions': 'Sumbangan saya',
    'Creator Studio': 'Studio Pencipta',
    'Create trusted local listings and follow every moderation decision.':
        'Cipta penyenaraian tempatan yang dipercayai dan ikuti setiap keputusan penyederhanaan.',
    'Create': 'Cipta',
    'Share a local Spot': 'Kongsi Tempat tempatan',
    'Add a real place with location details, recommendations, and an original photo.':
        'Tambah tempat sebenar dengan butiran lokasi, cadangan dan foto asal.',
    'AI Restaurant Import': 'Import Restoran AI',
    'Start from an individual TikTok or Instagram review post, then verify every generated field.':
        'Mulakan daripada hantaran ulasan TikTok atau Instagram individu, kemudian sahkan setiap medan yang dijana.',
    'Build a Guide': 'Bina Panduan',
    'Arrange approved listings and useful custom stops into a moderated local route.':
        'Susun penyenaraian yang diluluskan dan hentian tersuai yang berguna menjadi laluan tempatan yang disemak.',
    'Contribution pipeline': 'Aliran sumbangan',
    'Spot contributions': 'Sumbangan Tempat',
    'Restaurant contributions': 'Sumbangan restoran',
    'Guide contributions': 'Sumbangan panduan',
    'No contributions yet': 'Belum ada sumbangan',
    'Start with a place you know well.':
        'Mulakan dengan tempat yang anda kenali dengan baik.',
    'Creator · Malaysia': 'Pencipta · Malaysia',
    'Your local guide to Malaysia': 'Panduan tempatan anda ke Malaysia',
    'Your Malaysia': 'Malaysia anda',
    'Find a place worth the detour': 'Temui tempat yang berbaloi dikunjungi',
    'Browse trusted local places, restaurants, and community guides before you decide where to go.':
        'Terokai tempat tempatan, restoran dan panduan komuniti yang dipercayai sebelum memilih destinasi anda.',
    'Continue a plan, revisit a saved place, or discover somewhere local today.':
        'Teruskan rancangan, kunjungi semula tempat yang disimpan atau temui lokasi tempatan hari ini.',
    'Places to know': 'Tempat untuk dikenali',
    'Approved local picks from across Malaysia':
        'Pilihan tempatan yang diluluskan dari seluruh Malaysia',
    'Places will appear here when they are available.':
        'Tempat akan dipaparkan di sini apabila tersedia.',
    'Explore by mood': 'Teroka mengikut suasana',
    'Local Spots': 'Tempat Lokal',
    'Local Eats': 'Makanan Lokal',
    'Community Guides': 'Panduan Komuniti',
    'Explore Malaysia': 'Terokai Malaysia',
    'Continue planning': 'Teruskan perancangan',
    'Continue drafts and follow moderation decisions':
        'Teruskan draf dan ikuti keputusan penyederhanaan',
    'Add restaurant': 'Tambah restoran',
    'Submit Spot': 'Hantar Tempat',
    'Submit Guide': 'Hantar Panduan',
    'Manage discount': 'Urus diskaun',
    'Creator': 'Pencipta',
    'Tourist': 'Pelancong',
    'Guest': 'Tetamu',
    'English': 'English',
    'Bahasa Malaysia': 'Bahasa Malaysia',
    'Language': 'Bahasa',
    'Preview public experience': 'Pratonton pengalaman awam',
    'Applications, safety work, audit records, and workspace utilities.':
        'Permohonan, kerja keselamatan, rekod audit dan utiliti ruang kerja.',
    'Creator Applications': 'Permohonan Pencipta',
    'Review eligibility and information requests':
        'Semak kelayakan dan permintaan maklumat',
    'Reports': 'Laporan',
    'Resolve content and safety reports':
        'Selesaikan laporan kandungan dan keselamatan',
    'Account Appeals': 'Rayuan Akaun',
    'Review account access decisions': 'Semak keputusan akses akaun',
    'Trace administrative actions and reasons':
        'Jejaki tindakan pentadbiran dan sebabnya',
    'Open discovery without mixing it into Admin Overview':
        'Buka penemuan awam tanpa mencampurkannya ke dalam Gambaran Keseluruhan Admin',
    'End this administrator session': 'Tamatkan sesi pentadbir ini',
    'Load earlier notifications': 'Muatkan pemberitahuan terdahulu',
    'This notification’s destination is no longer available.':
        'Destinasi pemberitahuan ini tidak lagi tersedia.',
    'LiveLocal listing': 'Penyenaraian LiveLocal',
    'Custom stop': 'Hentian tersuai',
    'Approved Spot or Restaurant': 'Tempat atau Restoran yang diluluskan',
    'Choose an approved listing.': 'Pilih penyenaraian yang diluluskan.',
    'Custom stop name': 'Nama hentian tersuai',
    'Enter stop name.': 'Masukkan nama hentian.',
    'Approved restaurant': 'Restoran yang diluluskan',
    'Approximate follower count': 'Anggaran bilangan pengikut',
    'Back to top': 'Kembali ke atas',
    'Change profile photo': 'Tukar foto profil',
    'Clear filters': 'Kosongkan penapis',
    'Code': 'Kod',
    'Collection name': 'Nama koleksi',
    'Confirm New Password': 'Sahkan Kata Laluan Baharu',
    'Confirm Password': 'Sahkan Kata Laluan',
    'Create a travel guide': 'Cipta panduan perjalanan',
    'Cuisine type': 'Jenis masakan',
    'Delete review': 'Padam ulasan',
    'Description (optional)': 'Penerangan (pilihan)',
    'Discover places': 'Temui tempat',
    'Dislike review': 'Tidak suka ulasan',
    'Display name': 'Nama paparan',
    'Edit review': 'Sunting ulasan',
    'Email Address': 'Alamat e-mel',
    'Email address': 'Alamat e-mel',
    'Enter your name': 'Masukkan nama anda',
    'Explanation (optional)': 'Penjelasan (pilihan)',
    'Full Name': 'Nama Penuh',
    'HTTPS profile URL': 'URL profil HTTPS',
    'Internal decision reason': 'Sebab keputusan dalaman',
    'Like review': 'Suka ulasan',
    'Manage account access': 'Urus akses akaun',
    'Message shown to the user': 'Mesej yang ditunjukkan kepada pengguna',
    'Neighbourhood / area': 'Kawasan kejiranan / kawasan',
    'New Password': 'Kata Laluan Baharu',
    'New collection': 'Koleksi baharu',
    'Offer description': 'Penerangan tawaran',
    'Optional details': 'Butiran pilihan',
    'Become a LiveLocal Creator': 'Jadi Pencipta LiveLocal',
    'Apply to become a Creator': 'Mohon untuk menjadi Pencipta',
    'Creators share trusted restaurant recommendations and help travellers discover great local food.':
        'Pencipta berkongsi cadangan restoran yang dipercayai dan membantu pengembara menemukan makanan tempatan yang hebat.',
    'Creators share trusted restaurant recommendations and help travellers discover great local food. Applications are reviewed before Creator tools are unlocked.':
        'Pencipta berkongsi cadangan restoran yang dipercayai dan membantu pengembara menemukan makanan tempatan yang hebat. Permohonan disemak sebelum alat Pencipta dibuka.',
    'Creator & Community Guidelines': 'Garis Panduan Pencipta dan Komuniti',
    'Creator profile': 'Profil Pencipta',
    'Your public name and primary social platform':
        'Nama awam dan platform sosial utama anda',
    'Motivation & guidelines': 'Motivasi dan garis panduan',
    'Tell us why you would like to contribute':
        'Beritahu kami sebab anda ingin menyumbang',
    'Read the current creator rules summary':
        'Baca ringkasan peraturan Pencipta semasa',
    'I agree to the Creator and Community Rules':
        'Saya bersetuju dengan Peraturan Pencipta dan Komuniti',
    'Review and accept the rules to apply.':
        'Semak dan terima peraturan untuk memohon.',
    'I understand': 'Saya faham',
    'Application submitted': 'Permohonan dihantar',
    'Application sent': 'Permohonan telah dihantar',
    'Application in progress': 'Permohonan sedang diproses',
    'Your application is currently being reviewed by LiveLocal moderators. We will notify you once a decision is made.':
        'Permohonan anda sedang disemak oleh penyederhana LiveLocal. Kami akan memaklumkan anda apabila keputusan dibuat.',
    'Thanks for applying to become a LiveLocal Creator. Your account remains a Tourist while our team reviews your profile. Once approved, restaurant recommendations and Creator badges will be unlocked.':
        'Terima kasih kerana memohon menjadi Pencipta LiveLocal. Akaun anda kekal sebagai Pelancong sementara pasukan kami menyemak profil anda. Selepas diluluskan, cadangan restoran dan lencana Pencipta akan dibuka.',
    'Withdraw application': 'Tarik balik permohonan',
    'Application withdrawn.': 'Permohonan telah ditarik balik.',
    'Creator tools required': 'Alat Pencipta diperlukan',
    'Approved creator access is required.':
        'Akses Pencipta yang diluluskan diperlukan.',
    'Apply to become a Creator. Once approved by our team, Creator tools and restaurant submissions will be unlocked.':
        'Mohon untuk menjadi Pencipta. Selepas diluluskan oleh pasukan kami, alat Pencipta dan sumbangan restoran akan dibuka.',
    'Apply to become a Creator. Once your application is approved by our team, Creator tools and restaurant recommendations will be unlocked.':
        'Mohon untuk menjadi Pencipta. Selepas permohonan anda diluluskan, alat Pencipta dan cadangan restoran akan dibuka.',
    'LiveLocal Creator Program': 'Program Pencipta LiveLocal',
    'Application status:': 'Status permohonan:',
    'View application status': 'Lihat status permohonan',
    'Creator tools': 'Alat Pencipta',
    'Restaurant recommendations are submitted by approved LiveLocal Creators.':
        'Cadangan restoran dihantar oleh Pencipta LiveLocal yang diluluskan.',
    'Authentic dining, street food, and kopitiams recommended by verified food lovers.':
        'Tempat makan autentik, makanan jalanan dan kopitiam yang disyorkan oleh pencinta makanan yang disahkan.',
    'Local eats recommended by creators': 'Makanan tempatan cadangan Pencipta',
    'Submit a restaurant': 'Hantar restoran',
    'Create a listing for community moderation.':
        'Cipta penyenaraian untuk penyederhanaan komuniti.',
    'Create a discount': 'Cipta diskaun',
    'Share deals for your listings.': 'Kongsi tawaran untuk penyenaraian anda.',
    'No restaurants found': 'Tiada restoran ditemui',
    'Try a broader search or reset the filters.':
        'Cuba carian yang lebih luas atau tetapkan semula penapis.',
    'Restaurants could not be loaded': 'Restoran tidak dapat dimuatkan',
    'Maybe later': 'Mungkin kemudian',
    'Sign in to recommend a restaurant':
        'Log masuk untuk mencadangkan restoran',
    'Restaurant recommendations are published exclusively by approved Local Food Creators to maintain authentic, quality food guides.':
        'Cadangan restoran diterbitkan secara eksklusif oleh Pencipta Makanan Tempatan yang diluluskan untuk mengekalkan panduan makanan yang autentik dan berkualiti.',
    'Restaurant info': 'Maklumat restoran',
    'Basic details and cuisine style': 'Butiran asas dan gaya masakan',
    'Location details': 'Butiran lokasi',
    'Address and state in Malaysia': 'Alamat dan negeri di Malaysia',
    'Recommended dishes & social source':
        'Hidangan dicadangkan dan sumber sosial',
    'Highlight your top recommendations and video link':
        'Serlahkan cadangan utama dan pautan video anda',
    'Cover photo': 'Foto muka depan',
    'Add an appetizing photo of the food or venue':
        'Tambah foto makanan atau premis yang menarik',
    'Import from a review (Optional)': 'Import daripada ulasan (Pilihan)',
    'Auto-fill details from an Instagram or TikTok review post':
        'Isi butiran secara automatik daripada hantaran ulasan Instagram atau TikTok',
    'Choose a restaurant review:': 'Pilih ulasan restoran:',
    'AI-assisted draft generated. Review and edit all fields below.':
        'Draf bantuan AI telah dijana. Semak dan sunting semua medan di bawah.',
    'Continue manually': 'Teruskan secara manual',
    'Apply draft': 'Gunakan draf',
    'Applying this AI draft will replace the restaurant details you entered.':
        'Menggunakan draf AI ini akan menggantikan butiran restoran yang anda masukkan.',
    'Replace current details with this AI draft?':
        'Gantikan butiran semasa dengan draf AI ini?',
    'The generated candidate did not contain a valid review post.':
        'Cadangan yang dijana tidak mengandungi hantaran ulasan yang sah.',
    'Paste a TikTok review video or Instagram post/Reel link, not a profile link.':
        'Tampal pautan video ulasan TikTok atau hantaran/Reel Instagram, bukan pautan profil.',
    'Paste a valid TikTok or Instagram review video or post link.':
        'Tampal pautan video atau hantaran ulasan TikTok atau Instagram yang sah.',
    'Enter a supported TikTok or Instagram HTTPS URL.':
        'Masukkan URL HTTPS TikTok atau Instagram yang disokong.',
    'Enter a cuisine type (at least 2 characters).':
        'Masukkan jenis masakan (sekurang-kurangnya 2 aksara).',
    'Please select a cover photo.': 'Sila pilih foto muka depan.',
    'Confirm that you have permission to share the photo.':
        'Sahkan bahawa anda mempunyai kebenaran untuk berkongsi foto.',
    'Possible existing listing': 'Penyenaraian serupa mungkin wujud',
    'We found similar public listings. Avoid creating a duplicate when one of these is the same business.':
        'Kami menemui penyenaraian awam yang serupa. Elakkan pendua jika salah satu daripadanya ialah perniagaan yang sama.',
    'Draft discarded. You can use the existing listing.':
        'Draf dibuang. Anda boleh menggunakan penyenaraian sedia ada.',
    'Submit with explanation': 'Hantar dengan penjelasan',
    'Thanks for the recommendation': 'Terima kasih atas cadangan anda',
    'Submission sent': 'Sumbangan telah dihantar',
    'Your restaurant submission has been sent for moderation. Once approved by an administrator, it will appear in Local Eats.':
        'Sumbangan restoran anda telah dihantar untuk penyederhanaan. Selepas diluluskan oleh pentadbir, ia akan dipaparkan dalam Makanan Lokal.',
    'Discard my draft': 'Buang draf saya',
    'Manage discounts': 'Urus diskaun',
    'Your offers': 'Tawaran anda',
    'Create an offer': 'Cipta tawaran',
    'No approved owned restaurant': 'Tiada restoran milik anda yang diluluskan',
    'A restaurant must be approved and remain owned by your creator account before you can add a discount.':
        'Restoran mesti diluluskan dan kekal dimiliki oleh akaun Pencipta anda sebelum anda boleh menambah diskaun.',
    'No creator offers have been created yet.':
        'Belum ada tawaran Pencipta yang dicipta.',
    'Use 3–32 letters, numbers, hyphens or underscores.':
        'Gunakan 3–32 huruf, nombor, tanda sempang atau garis bawah.',
    'Choose a restaurant.': 'Pilih restoran.',
    'Expiry must be after the start time.':
        'Tarikh tamat mesti selepas waktu mula.',
    'Starts': 'Bermula',
    'Expires': 'Tamat',
    'Pause': 'Jeda',
    'Resume': 'Sambung',
    'Revoke': 'Batalkan',
    'Revoke this discount?': 'Batalkan diskaun ini?',
    'Revocation is immediate and cannot be reversed. The offer will stop appearing as active.':
        'Pembatalan berkuat kuasa serta-merta dan tidak boleh dipulihkan. Tawaran tidak lagi dipaparkan sebagai aktif.',
    'Discounts can only be attached to your approved listing. LiveLocal displays the offer but does not process payment or guarantee merchant acceptance.':
        'Diskaun hanya boleh dilampirkan pada penyenaraian anda yang diluluskan. LiveLocal memaparkan tawaran tetapi tidak memproses bayaran atau menjamin penerimaan peniaga.',
    'Active offers': 'Tawaran aktif',
    'Offers are promotional information. Redemption is subject to the participating business. LiveLocal does not process payment or guarantee acceptance.':
        'Tawaran ialah maklumat promosi. Penebusan tertakluk pada perniagaan yang mengambil bahagian. LiveLocal tidak memproses bayaran atau menjamin penerimaan.',
    'Discount code copied.': 'Kod diskaun disalin.',
    'This offer is no longer active. Refreshing offers…':
        'Tawaran ini tidak lagi aktif. Sedang memuat semula tawaran…',
    'Share a local place': 'Kongsi tempat tempatan',
    'Sign in to share a place': 'Log masuk untuk berkongsi tempat',
    'Sign in with your verified account to contribute places to LiveLocal.':
        'Log masuk dengan akaun yang disahkan untuk menyumbang tempat kepada LiveLocal.',
    'Place basics': 'Asas tempat',
    'Name and classification of this spot': 'Nama dan klasifikasi tempat ini',
    'Category': 'Kategori',
    'Select category.': 'Pilih kategori.',
    'Select state.': 'Pilih negeri.',
    'About this place': 'Tentang tempat ini',
    'Tell travellers what makes this spot special':
        'Beritahu pengembara perkara yang menjadikan tempat ini istimewa',
    'Where visitors can find this place': 'Lokasi tempat ini untuk dikunjungi',
    'Add an appealing landscape photo': 'Tambah foto landskap yang menarik',
    'Choose a clear photo of the place.': 'Pilih foto tempat yang jelas.',
    'This may already be listed': 'Tempat ini mungkin telah disenaraikan',
    'Review these probable matches before creating another listing:':
        'Semak padanan yang berkemungkinan ini sebelum mencipta penyenaraian lain:',
    'Use existing listing': 'Gunakan penyenaraian sedia ada',
    'Submit as different': 'Hantar sebagai tempat berbeza',
    'Draft discarded. Open the existing listing from discovery.':
        'Draf dibuang. Buka penyenaraian sedia ada melalui penemuan.',
    'Thanks for sharing this place': 'Terima kasih kerana berkongsi tempat ini',
    'Your submission is waiting for review. An administrator will verify the details before it appears in public discovery.':
        'Sumbangan anda sedang menunggu semakan. Pentadbir akan mengesahkan butiran sebelum ia dipaparkan dalam penemuan awam.',
    'Places could not be loaded': 'Tempat tidak dapat dimuatkan',
    'No matching places': 'Tiada tempat yang sepadan',
    'Try another search, category, or state filter.':
        'Cuba carian, kategori atau penapis negeri yang lain.',
    'About this Local Spot': 'Tentang Tempat Lokal ini',
    'Community Reviews': 'Ulasan Komuniti',
    'Write Review': 'Tulis Ulasan',
    'Submit Review': 'Hantar Ulasan',
    'Review submitted! Thank you.': 'Ulasan dihantar! Terima kasih.',
    'Failed to submit review. Please try again.':
        'Ulasan gagal dihantar. Sila cuba lagi.',
    'No reviews yet. Be the first local visitor to share your review!':
        'Belum ada ulasan. Jadilah pengunjung tempatan pertama yang berkongsi ulasan!',
    'No reviews yet. Share the first review.':
        'Belum ada ulasan. Kongsi ulasan pertama.',
    'Your Rating:': 'Penilaian anda:',
    'Delete your review?': 'Padam ulasan anda?',
    'The rating aggregate will be updated immediately. This cannot be undone.':
        'Penilaian keseluruhan akan dikemas kini serta-merta. Tindakan ini tidak boleh dibatalkan.',
    'This cannot be undone. The public rating will be recalculated.':
        'Tindakan ini tidak boleh dibatalkan. Penilaian awam akan dikira semula.',
    'Community reviews': 'Ulasan komuniti',
    'Write or edit': 'Tulis atau sunting',
    'Save review': 'Simpan ulasan',
    'Edited': 'Disunting',
    'Recommended dishes': 'Hidangan dicadangkan',
    'Restaurant': 'Restoran',
    'Address': 'Alamat',
    'Report': 'Lapor',
    'Report this listing': 'Laporkan penyenaraian ini',
    'Report this spot': 'Laporkan tempat ini',
    'Report this review': 'Laporkan ulasan ini',
    'Report review': 'Laporkan ulasan',
    'Report broken creator link': 'Laporkan pautan Pencipta yang rosak',
    'Block contributor': 'Sekat penyumbang',
    'Block creator': 'Sekat Pencipta',
    'Block reviewer': 'Sekat pengulas',
    'Hide this review for me': 'Sembunyikan ulasan ini untuk saya',
    'One report does not hide it from everyone.':
        'Satu laporan tidak menyembunyikannya daripada semua pengguna.',
    'Creator link unavailable': 'Pautan Pencipta tidak tersedia',
    'The creator link could not be opened on this device.':
        'Pautan Pencipta tidak dapat dibuka pada peranti ini.',
    'This creator review link is invalid and cannot be opened.':
        'Pautan ulasan Pencipta ini tidak sah dan tidak dapat dibuka.',
    'Open original review': 'Buka ulasan asal',
    'Sign in to create a guide': 'Log masuk untuk mencipta panduan',
    'Share your travel itineraries and local routes with the LiveLocal community.':
        'Kongsi itinerari perjalanan dan laluan tempatan anda dengan komuniti LiveLocal.',
    'Title, destination, and trip duration':
        'Tajuk, destinasi dan tempoh perjalanan',
    'Guide overview': 'Gambaran keseluruhan panduan',
    'Share a route, itinerary or local plan that helped you explore an area in Malaysia.':
        'Kongsi laluan, itinerari atau rancangan tempatan yang membantu anda menerokai kawasan di Malaysia.',
    'Ordered stops (Min. 2 stops)': 'Hentian tersusun (Min. 2 hentian)',
    'Add the sequence of places to visit along the route':
        'Tambah urutan tempat untuk dikunjungi di sepanjang laluan',
    'Add another stop': 'Tambah hentian lain',
    'Enter tips or directions for this stop.':
        'Masukkan petua atau arah untuk hentian ini.',
    'A travel guide requires at least 2 stops.':
        'Panduan perjalanan memerlukan sekurang-kurangnya 2 hentian.',
    'Submit guide for review': 'Hantar panduan untuk semakan',
    'Guide submitted': 'Panduan dihantar',
    'Guide submitted for review': 'Panduan dihantar untuk semakan',
    'Community travel guides are reviewed by LiveLocal before becoming public. Once approved, your itinerary will be visible to all travellers.':
        'Panduan perjalanan komuniti disemak oleh LiveLocal sebelum diterbitkan. Selepas diluluskan, itinerari anda akan dapat dilihat oleh semua pengembara.',
    'About this route': 'Tentang laluan ini',
    'Travel guide': 'Panduan perjalanan',
    'Ordered route overview': 'Gambaran keseluruhan laluan tersusun',
    'Route steps': 'Langkah laluan',
    'Follow the order below and check current local conditions before setting out.':
        'Ikuti urutan di bawah dan semak keadaan tempatan semasa sebelum bertolak.',
    'LiveLocal does not currently provide turn-by-turn navigation. This curated route is a planning guide, not a live safety or accessibility guarantee.':
        'LiveLocal tidak menyediakan navigasi belokan demi belokan pada masa ini. Laluan pilihan ini ialah panduan perancangan, bukan jaminan keselamatan atau kebolehcapaian secara langsung.',
    'Guides could not be loaded': 'Panduan tidak dapat dimuatkan',
    'No matching guides': 'Tiada panduan yang sepadan',
    'Try another search, state, or neighbourhood.':
        'Cuba carian, negeri atau kawasan kejiranan yang lain.',
    'Create a guide': 'Cipta panduan',
    'Saved collections': 'Koleksi disimpan',
    'Keep track of places you love': 'Jejaki tempat yang anda gemari',
    'Your curated collections': 'Koleksi pilihan anda',
    'Organize places for upcoming trips, food hunts, or weekend plans.':
        'Susun tempat untuk perjalanan, pencarian makanan atau rancangan hujung minggu akan datang.',
    'Sign in to LiveLocal': 'Log masuk ke LiveLocal',
    'Sign in to organize spots into custom collections and plan your day itineraries.':
        'Log masuk untuk menyusun tempat dalam koleksi tersuai dan merancang itinerari harian anda.',
    'Saved collections could not be loaded':
        'Koleksi disimpan tidak dapat dimuatkan',
    'No collections yet': 'Belum ada koleksi',
    'Create your first collection to start organizing places.':
        'Cipta koleksi pertama anda untuk mula menyusun tempat.',
    'Create collection': 'Cipta koleksi',
    'No places in this collection': 'Tiada tempat dalam koleksi ini',
    'Delete collection?': 'Padam koleksi?',
    'Rename collection': 'Namakan semula koleksi',
    'Plan route': 'Rancang laluan',
    'This place is no longer publicly available.':
        'Tempat ini tidak lagi tersedia kepada umum.',
    'Itineraries': 'Itinerari',
    'Plan a route from your saved places':
        'Rancang laluan daripada tempat yang anda simpan',
    'Choose a manual starting city or request your device location. Proximity order is computed to help you organize a smooth day out.':
        'Pilih bandar permulaan secara manual atau minta lokasi peranti anda. Susunan mengikut jarak dikira untuk membantu anda merancang perjalanan harian yang lancar.',
    'All saved places': 'Semua tempat disimpan',
    'Choose city': 'Pilih bandar',
    'Device location': 'Lokasi peranti',
    'Current location': 'Lokasi semasa',
    'LiveLocal will ask for foreground location only after you continue. Denying permission will not block discovery; you can return and choose a city.':
        'LiveLocal hanya akan meminta lokasi latar depan selepas anda meneruskan. Menolak kebenaran tidak menghalang penemuan; anda boleh kembali dan memilih bandar.',
    'Create itinerary': 'Cipta itinerari',
    'Suggested day itinerary': 'Itinerari harian dicadangkan',
    'Day breakdown': 'Pecahan hari',
    'Itinerary on Map': 'Itinerari pada Peta',
    'Saved itineraries': 'Itinerari disimpan',
    'No saved itineraries yet. Creating a route saves its order to your account.':
        'Belum ada itinerari disimpan. Mencipta laluan akan menyimpan susunannya pada akaun anda.',
    'No verified coordinates available for this route.':
        'Tiada koordinat disahkan tersedia untuk laluan ini.',
    'Optimised Travel Route': 'Laluan Perjalanan Dioptimumkan',
    'No notifications yet': 'Belum ada pemberitahuan',
    'Your account updates in one place': 'Kemas kini akaun anda di satu tempat',
    'Account and moderation updates will appear here.':
        'Kemas kini akaun dan penyederhanaan akan dipaparkan di sini.',
    'Sign in to view moderation decisions, creator application updates, and other personal notices.':
        'Log masuk untuk melihat keputusan penyederhanaan, kemas kini permohonan Pencipta dan notis peribadi lain.',
    'Notifications could not be loaded': 'Pemberitahuan tidak dapat dimuatkan',
    'Mark all read': 'Tandakan semua sebagai dibaca',
    'Contribution history': 'Sejarah sumbangan',
    'Track the status of your submitted places, travel guides, and creator applications.':
        'Jejaki status tempat, panduan perjalanan dan permohonan Pencipta yang anda hantar.',
    'Local spots': 'Tempat tempatan',
    'No places submitted': 'Tiada tempat dihantar',
    'Share heritage, nature or local spots with travellers.':
        'Kongsi warisan, alam semula jadi atau tempat tempatan dengan pengembara.',
    'Travel guides': 'Panduan perjalanan',
    'No guides submitted': 'Tiada panduan dihantar',
    'Create travel routes and itineraries for Malaysia.':
        'Cipta laluan perjalanan dan itinerari untuk Malaysia.',
    'No restaurants submitted': 'Tiada restoran dihantar',
    'Recommend authentic eateries and local food gems.':
        'Cadangkan tempat makan autentik dan permata makanan tempatan.',
    'Creator application': 'Permohonan Pencipta',
    'Tap to view your application status or details.':
        'Ketik untuk melihat status atau butiran permohonan anda.',
    'View published': 'Lihat yang diterbitkan',
    'Withdraw': 'Tarik balik',
    'Discard draft': 'Buang draf',
    'Discard this draft?': 'Buang draf ini?',
    'Discard this restaurant draft?': 'Buang draf restoran ini?',
    'Withdraw this restaurant revision?': 'Tarik balik pindaan restoran ini?',
    'Withdraw this submission?': 'Tarik balik sumbangan ini?',
    'Review before submitting': 'Semak sebelum menghantar',
    'Add a cover photo': 'Tambah foto muka depan',
    'Choose from gallery': 'Pilih daripada galeri',
    'Take a photo': 'Ambil foto',
    'Could not load image. Please try again.':
        'Imej tidak dapat dimuatkan. Sila cuba lagi.',
    'JPG, PNG under 5MB': 'JPG, PNG di bawah 5MB',
    'I own the rights to this photo or have explicit permission to publish it.':
        'Saya memiliki hak terhadap foto ini atau mempunyai kebenaran jelas untuk menerbitkannya.',
    'Loading content': 'Sedang memuatkan kandungan',
    'Review queue': 'Barisan semakan',
    'Moderate submissions, reports, and appeals':
        'Sederhanakan sumbangan, laporan dan rayuan',
    'Queue is clear': 'Barisan telah selesai',
    'No spot submissions currently need a decision.':
        'Tiada sumbangan tempat yang memerlukan keputusan buat masa ini.',
    'No restaurant submissions currently need a decision.':
        'Tiada sumbangan restoran yang memerlukan keputusan buat masa ini.',
    'No guide submissions currently need a decision.':
        'Tiada sumbangan panduan yang memerlukan keputusan buat masa ini.',
    'No Creator applications currently need a decision.':
        'Tiada permohonan Pencipta yang memerlukan keputusan buat masa ini.',
    'No content reports currently awaiting moderation.':
        'Tiada laporan kandungan yang menunggu penyederhanaan.',
    'No account appeals currently awaiting review.':
        'Tiada rayuan akaun yang menunggu semakan.',
    'No review items found.': 'Tiada perkara semakan ditemui.',
    'Approve': 'Luluskan',
    'Reject': 'Tolak',
    'Request info': 'Minta maklumat',
    'Escalate': 'Rujuk lanjut',
    'Dismiss': 'Tolak laporan',
    'Accept & restore': 'Terima dan pulihkan',
    'Do not accept': 'Jangan terima',
    'AI-assisted': 'Bantuan AI',
    'Manage user roles and account access permissions':
        'Urus peranan pengguna dan kebenaran akses akaun',
    'No accounts found': 'Tiada akaun ditemui',
    'Temporarily restrict': 'Sekat buat sementara waktu',
    'Permanently ban': 'Sekat secara kekal',
    'Restore access': 'Pulihkan akses',
    'You cannot change your own access.':
        'Anda tidak boleh mengubah akses sendiri.',
    'Accountability log of administrative decisions and events':
        'Log kebertanggungjawaban bagi keputusan dan peristiwa pentadbiran',
    'No audit records': 'Tiada rekod audit',
    'Curate, revise, and publish neighbourhood guides':
        'Pilih, pinda dan terbitkan panduan kawasan kejiranan',
    'Manage LiveLocal neighbourhood guides':
        'Urus panduan kawasan kejiranan LiveLocal',
    'Admin-created guides that are still being prepared.':
        'Panduan ciptaan admin yang masih sedang disediakan.',
    'Guides currently visible to LiveLocal users.':
        'Panduan yang kini dapat dilihat oleh pengguna LiveLocal.',
    'Pending submissions could not be loaded.':
        'Sumbangan tempat tidak dapat dimuatkan.',
    'Restaurant submissions could not be loaded.':
        'Sumbangan restoran tidak dapat dimuatkan.',
    'Guide submissions could not be loaded.':
        'Sumbangan panduan tidak dapat dimuatkan.',
    'Creator applications could not be loaded.':
        'Permohonan Pencipta tidak dapat dimuatkan.',
    'Users could not be loaded.': 'Pengguna tidak dapat dimuatkan.',
    'Content reports could not be loaded.':
        'Laporan kandungan tidak dapat dimuatkan.',
    'Overview metrics could not be loaded.':
        'Metrik ringkasan tidak dapat dimuatkan.',
    'Audit history could not be loaded.':
        'Sejarah audit tidak dapat dimuatkan.',
    'Account appeals could not be loaded.':
        'Rayuan akaun tidak dapat dimuatkan.',
    'No admin drafts': 'Tiada draf admin',
    'No published guides': 'Tiada panduan diterbitkan',
    'New draft': 'Draf baharu',
    'Edit draft': 'Sunting draf',
    'Archive': 'Arkibkan',
    'Publish': 'Terbitkan',
    'Revise': 'Pinda',
    'Archive this guide?': 'Arkibkan panduan ini?',
    'Publish this guide?': 'Terbitkan panduan ini?',
    'Admin-curated neighbourhood guide':
        'Panduan kawasan kejiranan pilihan admin',
    'Guide draft saved. Review it in the admin dashboard.':
        'Draf panduan disimpan. Semaknya dalam papan pemuka admin.',
    'Provide exactly one walking instruction for each stop.':
        'Berikan tepat satu arahan berjalan kaki untuk setiap hentian.',
    '1 day': '1 hari',
    '7 days': '7 hari',
    '30 days': '30 hari',
    '1. Authenticity: Only recommend places you have personally visited and genuinely recommend.':
        '1. Keaslian: Cadangkan hanya tempat yang pernah anda lawati sendiri dan benar-benar anda syorkan.',
    'All Malaysia': 'Seluruh Malaysia',
    'All States': 'Semua Negeri',
    'Price range': 'Julat harga',
    'Place name': 'Nama tempat',
    'City or district': 'Bandar atau daerah',
    'Full address': 'Alamat penuh',
    'Best time to visit': 'Waktu terbaik untuk melawat',
    'Things to do or order': 'Aktiviti atau pesanan dicadangkan',
    'Restaurant name': 'Nama restoran',
    'Reviewed / recommended dishes': 'Hidangan diulas / dicadangkan',
    'TikTok or Instagram video link': 'Pautan video TikTok atau Instagram',
    'Content focus / category': 'Fokus / kategori kandungan',
    'Why you want to contribute': 'Sebab anda ingin menyumbang',
    'Enter a non-negative whole number.':
        'Masukkan nombor bulat yang bukan negatif.',
    'Choose a restaurant review': 'Pilih ulasan restoran',
    'Find authentic kopitiams, pasar malams, hidden gems and local eats — recommended by real Malaysians and trusted Creators':
        'Temui kopitiam autentik, pasar malam, lokasi tersembunyi dan makanan tempatan — dicadangkan oleh rakyat Malaysia sebenar dan Pencipta yang dipercayai',
    'Get Started': 'Mulakan',
    'I already have an account': 'Saya sudah mempunyai akaun',
    'Proudly supporting Visit Malaysia 2026':
        'Dengan bangganya menyokong Tahun Melawat Malaysia 2026',
    '🗺️ Explore Like a Local': '🗺️ Teroka Seperti Orang Tempatan',
    "Curated walking guides for Malaysia's hidden gems":
        'Panduan berjalan kaki pilihan untuk lokasi tersembunyi di Malaysia',
    "AI uses the review to suggest details. You'll review everything before submitting.":
        'AI menggunakan ulasan untuk mencadangkan butiran. Anda akan menyemak semuanya sebelum menghantar.',
    'Default collection for your saved places':
        'Koleksi lalai untuk tempat yang anda simpan',
    'Save to a collection': 'Simpan ke dalam koleksi',
    'Submit Report': 'Hantar Laporan',
    'You will no longer see this account’s public reviews, spots, or restaurant listings. They will not be notified. You can undo this from your account settings.':
        'Anda tidak lagi akan melihat ulasan awam, tempat atau penyenaraian restoran daripada akaun ini. Mereka tidak akan dimaklumkan. Anda boleh membatalkannya melalui tetapan akaun.',
    'Exclusive Discount Code Alert': 'Makluman Kod Diskaun Eksklusif',
    'New Local Spot Approved!': 'Tempat Lokal Baharu Diluluskan!',
    'Chop Seng Hin Kopitiam in Penang is now live on LiveLocal.':
        'Chop Seng Hin Kopitiam di Penang kini diterbitkan di LiveLocal.',
    'KL Foodie added a 10% discount code for Ah Hock Hawker CKT in Penang!':
        'KL Foodie menambah kod diskaun 10% untuk Ah Hock Hawker CKT di Penang!',
    'Free Sirap Bandung drink with any Nasi Kandar set purchase':
        'Minuman Sirap Bandung percuma dengan pembelian mana-mana set Nasi Kandar',
    'Get 10% OFF any Char Kuey Teow order when showing LiveLocal App':
        'Nikmati DISKAUN 10% bagi sebarang pesanan Char Kuey Teow apabila menunjukkan aplikasi LiveLocal',
    'Plan title': 'Tajuk rancangan',
    'Primary social platform': 'Platform sosial utama',
    'Recommend a restaurant': 'Cadangkan restoran',
    'Recorded in the admin audit history.':
        'Direkodkan dalam sejarah audit admin.',
    'Redemption terms': 'Terma penebusan',
    'Remove from collection': 'Alih keluar daripada koleksi',
    'Remove photo': 'Alih keluar foto',
    'Remove stop': 'Alih keluar hentian',
    'Rename': 'Namakan semula',
    'Replace photo': 'Gantikan foto',
    'Report this guide': 'Laporkan panduan ini',
    'Reset filters': 'Tetapkan semula penapis',
    'Restaurant options': 'Pilihan restoran',
    'Restriction duration': 'Tempoh sekatan',
    'Review actions': 'Tindakan ulasan',
    'Search audit records by action, actor, or reason':
        'Cari rekod audit mengikut tindakan, pelaku atau sebab',
    'Search by name or email': 'Cari mengikut nama atau e-mel',
    'Search guides by title or area':
        'Cari panduan mengikut tajuk atau kawasan',
    'Search restaurants, cuisines, or dishes':
        'Cari restoran, masakan atau hidangan',
    'Select category': 'Pilih kategori',
    'Select state': 'Pilih negeri',
    'Share a place': 'Kongsi tempat',
    'Share your experience at this spot...':
        'Kongsi pengalaman anda di tempat ini...',
    'Source collection': 'Koleksi sumber',
    'Spot safety options': 'Pilihan keselamatan Tempat',
    'Starting city': 'Bandar permulaan',
    'State': 'Negeri',
    'TikTok or Instagram review link': 'Pautan ulasan TikTok atau Instagram',
    'Tips & walking directions': 'Petua dan arah berjalan kaki',
    'Type DELETE to confirm': 'Taip DELETE untuk mengesahkan',
    'View on map': 'Lihat pada peta',
    'Why is this a different place?': 'Mengapa ini tempat yang berbeza?',
    'Why this is a different listing': 'Mengapa ini penyenaraian yang berbeza',
    'Your experience': 'Pengalaman anda',
    'e.g. 1 day, Half day, 3D2N': 'cth. 1 hari, Separuh hari, 3H2M',
    'e.g. 120 Campbell Street, 10100 George Town':
        'cth. 120 Campbell Street, 10100 George Town',
    'e.g. 5000': 'cth. 5000',
    'e.g. George Town, Ipoh Old Town': 'cth. George Town, Pekan Lama Ipoh',
    'e.g. George Town, Petaling Jaya': 'cth. George Town, Petaling Jaya',
    'e.g. Line Clear Nasi Kandar': 'cth. Line Clear Nasi Kandar',
    'e.g. Penang Foodie Guide, Alex Eats':
        'cth. Penang Foodie Guide, Alex Eats',
    'e.g. Penang Street Food in One Day':
        'cth. Makanan Jalanan Penang dalam Sehari',
    'e.g. Toh Soon Cafe, Hin Bus Depot': 'cth. Toh Soon Cafe, Hin Bus Depot',
    'e.g. Weekend in Penang, KL Coffee':
        'cth. Hujung Minggu di Penang, Kopi KL',
    'Describe the atmosphere, specialty, heritage or local significance...':
        'Terangkan suasana, keistimewaan, warisan atau kepentingan tempat ini kepada komuniti...',
    'e.g. Morning for fresh toast, sunset for sea breeze':
        'cth. Pagi untuk roti bakar segar, waktu senja untuk bayu laut',
    'e.g. Order charcoal toast, stroll through the art market':
        'cth. Pesan roti bakar arang, berjalan di pasar seni',
    'Describe the route theme, ideal timing, and general highlights...':
        'Terangkan tema laluan, waktu yang sesuai dan tarikan utamanya...',
    'Verified LiveLocal listings are labelled separately from custom stops.':
        'Penyenaraian LiveLocal yang disahkan dilabel berasingan daripada hentian tersuai.',
    'e.g. MRT exit, meeting point, or landmark':
        'cth. pintu keluar MRT, tempat pertemuan atau mercu tanda',
    'Custom stops are context only and are not approved LiveLocal listings.':
        'Hentian tersuai hanya memberi konteks dan bukan penyenaraian LiveLocal yang diluluskan.',
    'e.g. Order charcoal toast and coffee, then walk 5 mins to Armenian St.':
        'cth. Pesan roti bakar arang dan kopi, kemudian berjalan 5 minit ke Armenian St.',
    'e.g. Street food, Heritage cafes, Local hidden gems':
        'cth. Makanan jalanan, kafe warisan, lokasi tempatan tersembunyi',
    'Tell us about your local discoveries, culinary background, or passion for sharing Malaysian food...':
        'Kongsi penemuan tempatan, latar kulinari atau minat anda berkongsi makanan Malaysia...',
    'State exclusions, minimum spend, and how to redeem.':
        'Nyatakan pengecualian, perbelanjaan minimum dan cara menebus.',
    'Paste a TikTok video or Instagram Reel/post link':
        'Tampal pautan video TikTok atau Reel/hantaran Instagram',
    'e.g. Hainanese, Peranakan / Nyonya, Kopitiam':
        'cth. Hainan, Peranakan / Nyonya, Kopitiam',
    'e.g. Nasi Kandar with fried chicken and salted egg':
        'cth. Nasi kandar dengan ayam goreng dan telur masin',
    'Displayed to the user on restricted account screen.':
        'Ditunjukkan kepada pengguna pada skrin akaun terhad.',
    'Remove from saved': 'Alih keluar daripada simpanan',
    'Save place': 'Simpan tempat',
    'Saved to collections': 'Disimpan dalam koleksi',
    'Save to collection': 'Simpan ke koleksi',
    'Submit guide': 'Hantar panduan',
    'What happens when you open it?': 'Apakah yang berlaku apabila dibuka?',
    'Additional context (optional)': 'Konteks tambahan (pilihan)',
    'Show password': 'Tunjukkan kata laluan',
    'Hide password': 'Sembunyikan kata laluan',
    'Show password confirmation': 'Tunjukkan pengesahan kata laluan',
    'Hide password confirmation': 'Sembunyikan pengesahan kata laluan',
    'Review photos': 'Foto ulasan',
    'Optional · up to 3 original photos': 'Pilihan · sehingga 3 foto asal',
    'Use JPG, PNG, or WebP photos smaller than 6 MB each.':
        'Gunakan foto JPG, PNG atau WebP yang lebih kecil daripada 6 MB setiap satu.',
    'Review photos could not be opened. Try again.':
        'Foto ulasan tidak dapat dibuka. Cuba lagi.',
    'Only upload photos you own or have permission to publish. JPG, PNG, or WebP; 6 MB each.':
        'Muat naik hanya foto milik anda atau yang anda dibenarkan terbitkan. JPG, PNG atau WebP; 6 MB setiap satu.',
    'Add photo': 'Tambah foto',
    'Verify your email before signing in.':
        'Sahkan e-mel anda sebelum log masuk.',
    'This email is already registered. Try signing in.':
        'E-mel ini telah didaftarkan. Cuba log masuk.',
    'Authentication could not be completed. Check your details and try again.':
        'Pengesahan tidak dapat diselesaikan. Semak butiran anda dan cuba lagi.',
    'Community Rules acceptance could not be saved. Try again.':
        'Penerimaan Peraturan Komuniti tidak dapat disimpan. Cuba lagi.',
    'Spot approved': 'Tempat diluluskan',
    'Spot needs changes': 'Tempat memerlukan perubahan',
    'Restaurant approved': 'Restoran diluluskan',
    'Restaurant needs changes': 'Restoran memerlukan perubahan',
    'Guide approved': 'Panduan diluluskan',
    'Guide needs changes': 'Panduan memerlukan perubahan',
    'Creator application approved': 'Permohonan Pencipta diluluskan',
    'Creator application needs information':
        'Permohonan Pencipta memerlukan maklumat',
    'Creator application decision': 'Keputusan permohonan Pencipta',
    'Report reviewed': 'Laporan telah disemak',
    'The reported content was actioned.':
        'Tindakan telah diambil terhadap kandungan yang dilaporkan.',
    'The report was reviewed and dismissed.':
        'Laporan telah disemak dan ditolak.',
    'The report was escalated for further review.':
        'Laporan telah dirujuk untuk semakan lanjut.',
    'Content moderation action': 'Tindakan penyederhanaan kandungan',
    'Account access changed': 'Akses akaun telah berubah',
    'Appeal decision recorded': 'Keputusan rayuan telah direkodkan',
    'LiveLocal is not configured': 'LiveLocal belum dikonfigurasikan',
    'The configured backend could not be initialized. Check the environment settings and try again.':
        'Bahagian belakang yang dikonfigurasikan tidak dapat dimulakan. Semak tetapan persekitaran dan cuba lagi.',
    'The requested spot is unavailable.': 'Tempat yang diminta tidak tersedia.',
    'The requested restaurant is unavailable.':
        'Restoran yang diminta tidak tersedia.',
    'The requested guide is unavailable.':
        'Panduan yang diminta tidak tersedia.',
    'Create Account': 'Cipta Akaun',
    'Create your account': 'Cipta akaun anda',
    'Join thousands discovering authentic Malaysia':
        'Sertai ribuan pengguna yang menerokai Malaysia yang autentik',
    'All new accounts start as tourists.':
        'Semua akaun baharu bermula sebagai pelancong.',
    'Already have an account?': 'Sudah mempunyai akaun?',
    "Don't have an account?": 'Belum mempunyai akaun?',
    'Log In': 'Log Masuk',
    'Log in': 'Log masuk',
    'Sign up': 'Daftar',
    'Demo mode uses the fixed password 123456 and does not contact production services.':
        'Mod demo menggunakan kata laluan tetap 123456 dan tidak menghubungi perkhidmatan produksi.',
    'Recover your account': 'Pulihkan akaun anda',
    'Enter your account email. For privacy, the result does not reveal whether an account exists.':
        'Masukkan e-mel akaun anda. Demi privasi, hasilnya tidak mendedahkan sama ada akaun tersebut wujud.',
    'Reset password': 'Tetapkan semula kata laluan',
    'Send reset link': 'Hantar pautan tetapan semula',
    'Set New Password': 'Tetapkan Kata Laluan Baharu',
    'Create new password': 'Cipta kata laluan baharu',
    'Enter and confirm your new password below. It must meet the standard security requirements.':
        'Masukkan dan sahkan kata laluan baharu anda di bawah. Kata laluan mesti memenuhi keperluan keselamatan standard.',
    'Requirements: 10+ characters with at least one letter and one number.':
        'Keperluan: 10 aksara atau lebih dengan sekurang-kurangnya satu huruf dan satu nombor.',
    'Update Password': 'Kemas Kini Kata Laluan',
    'Password updated successfully. Please log in with your new password.':
        'Kata laluan berjaya dikemas kini. Sila log masuk dengan kata laluan baharu anda.',
    'Full name is required': 'Nama penuh diperlukan',
    'Use between 2 and 80 characters': 'Gunakan antara 2 hingga 80 aksara',
    'Email address is required': 'Alamat e-mel diperlukan',
    'Enter a valid email address': 'Masukkan alamat e-mel yang sah',
    'Enter a valid email address.': 'Masukkan alamat e-mel yang sah.',
    'Password is required': 'Kata laluan diperlukan',
    'Use 10+ characters with a letter and number':
        'Gunakan sekurang-kurangnya 10 aksara dengan satu huruf dan nombor',
    'Confirm password is required': 'Pengesahan kata laluan diperlukan',
    'Passwords do not match': 'Kata laluan tidak sepadan',
    'Use a display name between 2 and 80 characters.':
        'Gunakan nama paparan antara 2 hingga 80 aksara.',
    'An in-app appeal is unavailable because this account state has no auditable decision record.':
        'Rayuan dalam aplikasi tidak tersedia kerana keadaan akaun ini tiada rekod keputusan yang boleh diaudit.',
    'I believe this is a mistake': 'Saya percaya ini satu kesilapan',
    'My account was compromised': 'Akaun saya telah diceroboh',
    'Important context is missing': 'Konteks penting tiada',
    'Another reason': 'Sebab lain',
    'Appeal submitted for review.': 'Rayuan dihantar untuk semakan.',
    'We will review your appeal as soon as reasonably possible.':
        'Kami akan menyemak rayuan anda secepat yang munasabah.',
    'Your deletion request was cancelled.':
        'Permintaan pemadaman anda telah dibatalkan.',
    'Edit profile': 'Sunting profil',
    'Save changes': 'Simpan perubahan',
    'Profile updated.': 'Profil dikemas kini.',
    'Profile photo updated.': 'Foto profil dikemas kini.',
    'Verified': 'Disahkan',
    'Your activity': 'Aktiviti anda',
    'Your submissions': 'Sumbangan anda',
    'Drafts, review status and revisions': 'Draf, status semakan dan pindaan',
    'View your in-app history': 'Lihat sejarah dalam aplikasi anda',
    'Privacy & safety': 'Privasi dan keselamatan',
    'Blocked accounts': 'Akaun disekat',
    'Review or undo hidden accounts': 'Semak atau batalkan penyembunyian akaun',
    'Community Rules': 'Peraturan Komuniti',
    'Privacy Policy': 'Dasar Privasi',
    'Terms of Service': 'Terma Perkhidmatan',
    'Privacy': 'Privasi',
    'Terms': 'Terma',
    'Support': 'Sokongan',
    'Delete account': 'Padam akaun',
    'Schedule permanent account deletion': 'Jadualkan pemadaman akaun kekal',
    'Schedule account deletion?': 'Jadualkan pemadaman akaun?',
    'Enter your password and type DELETE.':
        'Masukkan kata laluan anda dan taip DELETE.',
    'Your account will be disabled now and scheduled for permanent deletion after 14 days. You can recover your account during this grace period by signing in and confirming recovery.':
        'Akaun anda akan dinyahaktifkan sekarang dan dijadualkan untuk pemadaman kekal selepas 14 hari. Anda boleh memulihkan akaun dalam tempoh ihsan ini dengan log masuk dan mengesahkan pemulihan.',
    'Keep account': 'Kekalkan akaun',
    'Schedule deletion': 'Jadualkan pemadaman',
    'Account deletion scheduled.': 'Pemadaman akaun telah dijadualkan.',
    'Could not open the link. Please visit livelocal.app/support':
        'Pautan tidak dapat dibuka. Sila lawati livelocal.app/support',
    'An error occurred while opening the link. Please visit livelocal.app/support':
        'Ralat berlaku semasa membuka pautan. Sila lawati livelocal.app/support',
    'Sign in to make LiveLocal yours':
        'Log masuk untuk menyesuaikan pengalaman LiveLocal anda',
    'Save places, build itineraries, review local favourites and manage your submissions.':
        'Simpan tempat, bina itinerari, ulas pilihan tempatan dan urus sumbangan anda.',
    'Community Rules Update': 'Kemas Kini Peraturan Komuniti',
    'To keep our community safe and welcoming, we require all users to accept our updated Community Rules before submitting content.':
        'Untuk memastikan komuniti kita selamat dan mesra, semua pengguna perlu menerima Peraturan Komuniti yang dikemas kini sebelum menghantar kandungan.',
    'Read Community Rules': 'Baca Peraturan Komuniti',
    'Agree & Continue': 'Setuju dan Teruskan',
    'Could not open the link. Please visit livelocal.app/rules':
        'Pautan tidak dapat dibuka. Sila lawati livelocal.app/rules',
    'An unexpected error occurred': 'Ralat yang tidak dijangka berlaku',
    'Blocked accounts unavailable': 'Akaun disekat tidak tersedia',
    'Account blocking requires the secure Supabase backend.':
        'Penyekatan akaun memerlukan bahagian belakang Supabase yang selamat.',
    'Accounts you block from public content appear here.':
        'Akaun yang anda sekat daripada kandungan awam dipaparkan di sini.',
    'No blocked accounts': 'Tiada akaun disekat',
    'Their public content is hidden': 'Kandungan awam mereka disembunyikan',
    'Unblock': 'Nyahsekat',
    'Unavailable in demo': 'Tidak tersedia dalam mod demo',
    'Block account': 'Sekat akaun',
    'Block this account?': 'Sekat akaun ini?',
    'Their public content is hidden from your experience. You can undo this from Profile.':
        'Kandungan awam mereka disembunyikan daripada pengalaman anda. Anda boleh membatalkannya melalui Profil.',
    'Hide this content for me': 'Sembunyikan kandungan ini untuk saya',
    'A report does not hide content for everyone before review.':
        'Laporan tidak menyembunyikan kandungan daripada semua pengguna sebelum semakan.',
    'Submit report': 'Hantar laporan',
    'Spam': 'Spam',
    'Misleading': 'Mengelirukan',
    'Harassment': 'Gangguan',
    'Hateful content': 'Kandungan berunsur kebencian',
    'Dangerous content': 'Kandungan berbahaya',
    'Privacy concern': 'Kebimbangan privasi',
    'Safety concern': 'Kebimbangan keselamatan',
    'Place has closed': 'Tempat telah ditutup',
    'Other': 'Lain-lain',
    'Your appeal was accepted and account access was restored.':
        'Rayuan anda diterima dan akses akaun telah dipulihkan.',
    'Your appeal was reviewed. Open account status for the decision.':
        'Rayuan anda telah disemak. Buka status akaun untuk melihat keputusan.',
    'Unread': 'Belum dibaca',
    'Just now': 'Baru sahaja',
  };
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'ms';

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

extension AppLocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String tr(String source) => l10n.translate(source);
  String? trNullable(String? source) =>
      source == null ? null : l10n.translate(source);
}
