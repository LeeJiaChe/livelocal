import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/core/config/legal_urls.dart';
import 'package:live_local/features/auth/domain/account_identity.dart';
import 'package:live_local/features/auth/presentation/auth_controller.dart';
import 'package:live_local/features/moderation/presentation/moderation_controller.dart';
import 'package:live_local/features/profile/presentation/account_controller.dart';
import 'package:live_local/screens/profile_screen.dart';
import 'package:provider/provider.dart';

class _FakeAppLauncher implements AppLauncher {
  Uri? lastLaunched;
  @override
  Future<bool> launch(Uri url) async {
    lastLaunched = url;
    return true;
  }
}

class _FakeAuthController extends ChangeNotifier implements AuthController {
  AccountIdentity? _currentUser;
  bool logoutCalled = false;

  @override
  AccountIdentity? get currentUser => _currentUser;

  @override
  bool get isLoading => false;

  void setUser(AccountIdentity? user) {
    _currentUser = user;
    notifyListeners();
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    _currentUser = null;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAccountController extends ChangeNotifier
    implements AccountController {
  String? updatedDisplayName;
  bool updateDisplayNameSucceeds = true;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  Future<bool> updateDisplayName(String name) async {
    updatedDisplayName = name;
    return updateDisplayNameSucceeds;
  }

  @override
  Future<bool> requestDeletion(String password) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeModerationController extends ChangeNotifier
    implements ModerationController {
  bool userBlockingSupported = true;

  @override
  bool get supportsUserBlocking => userBlockingSupported;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _buildProfileApp({
  required _FakeAuthController auth,
  required _FakeAccountController account,
  required _FakeModerationController moderation,
  AppLauncher? launcher,
  Size? screenSize,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthController>.value(value: auth),
      ChangeNotifierProvider<AccountController>.value(value: account),
      ChangeNotifierProvider<ModerationController>.value(value: moderation),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: screenSize ?? const Size(400, 800),
        ),
        child: ProfileScreen(launcher: launcher),
      ),
      routes: {
        '/login': (_) => const Scaffold(body: Text('Login Screen Mock')),
        '/register': (_) => const Scaffold(body: Text('Register Screen Mock')),
        '/creator-application': (_) =>
            const Scaffold(body: Text('Creator Application Mock')),
        '/my-submissions': (_) =>
            const Scaffold(body: Text('My Submissions Mock')),
        '/notifications': (_) =>
            const Scaffold(body: Text('Notifications Mock')),
        '/blocked-users': (_) =>
            const Scaffold(body: Text('Blocked Users Mock')),
      },
    ),
  );
}

void main() {
  group('Profile Screen UX Redesign Tests', () {
    late _FakeAuthController fakeAuth;
    late _FakeAccountController fakeAccount;
    late _FakeModerationController fakeModeration;
    late _FakeAppLauncher fakeLauncher;

    setUp(() {
      fakeAuth = _FakeAuthController();
      fakeAccount = _FakeAccountController();
      fakeModeration = _FakeModerationController();
      fakeLauncher = _FakeAppLauncher();
    });

    testWidgets(
        'Guest Profile displays clean prompt and routes to login/register',
        (tester) async {
      fakeAuth.setUser(null);

      await tester.pumpWidget(
        _buildProfileApp(
          auth: fakeAuth,
          account: fakeAccount,
          moderation: fakeModeration,
          launcher: fakeLauncher,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sign in to make LiveLocal yours'), findsOneWidget);
      expect(
        find.text(
          'Save places, build itineraries, review local favourites and manage your submissions.',
        ),
        findsOneWidget,
      );
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('Delete account'), findsNothing);
      expect(find.byKey(const Key('legal_terms')), findsOneWidget);

      // Tap Sign in
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Login Screen Mock'), findsOneWidget);
    });

    testWidgets(
        'Authenticated Tourist Profile renders hero, creator card, activity, and actions',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeAuth.setUser(
        const AccountIdentity(
          id: 'tourist-1',
          email: 'tourist@example.com',
          fullName: 'Ahmad Faiz',
          role: AppRole.tourist,
          accessStatus: AccountAccessStatus.active,
          emailVerified: true,
        ),
      );

      await tester.pumpWidget(
        _buildProfileApp(
          auth: fakeAuth,
          account: fakeAccount,
          moderation: fakeModeration,
          launcher: fakeLauncher,
        ),
      );

      await tester.pumpAndSettle();

      // Hero section
      expect(find.text('Ahmad Faiz'), findsOneWidget);
      expect(find.text('tourist@example.com'), findsOneWidget);
      expect(find.text('Tourist'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Edit profile'), findsOneWidget);

      // Creator Callout (tourist only)
      expect(find.text('Become a local creator'), findsOneWidget);
      expect(find.text('Apply as creator'), findsOneWidget);

      // Your activity
      expect(find.text('Your activity'), findsOneWidget);
      expect(find.text('Your submissions'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);

      // Privacy & safety
      expect(find.text('Privacy & safety'), findsOneWidget);
      expect(find.text('Blocked accounts'), findsOneWidget);
      expect(find.text('Delete account'), findsOneWidget);

      // Sign out
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets(
        'Creator profile shows Creator badge and hides creator application callout',
        (tester) async {
      fakeAuth.setUser(
        const AccountIdentity(
          id: 'creator-1',
          email: 'creator@example.com',
          fullName: 'Siti Nurhaliza',
          role: AppRole.influencer,
          accessStatus: AccountAccessStatus.active,
          emailVerified: true,
        ),
      );

      await tester.pumpWidget(
        _buildProfileApp(
          auth: fakeAuth,
          account: fakeAccount,
          moderation: fakeModeration,
          launcher: fakeLauncher,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Siti Nurhaliza'), findsOneWidget);
      expect(find.text('Creator'), findsOneWidget);
      expect(find.text('Become a local creator'), findsNothing);
      expect(find.text('Apply as creator'), findsNothing);
    });

    testWidgets(
        'Edit profile bottom sheet opens, validates, and saves display name',
        (tester) async {
      fakeAuth.setUser(
        const AccountIdentity(
          id: 'user-1',
          email: 'user@example.com',
          fullName: 'Original Name',
          role: AppRole.tourist,
          accessStatus: AccountAccessStatus.active,
          emailVerified: true,
        ),
      );

      await tester.pumpWidget(
        _buildProfileApp(
          auth: fakeAuth,
          account: fakeAccount,
          moderation: fakeModeration,
          launcher: fakeLauncher,
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Edit profile'
      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();

      // Bottom sheet is visible
      expect(find.text('Display name'), findsOneWidget);
      expect(
        find.textContaining(
            'Email (user@example.com) changes are not currently available here.'),
        findsOneWidget,
      );

      // Enter invalid single-character name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Original Name'),
        'A',
      );
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(
        find.text('Use a display name between 2 and 80 characters.'),
        findsOneWidget,
      );
      expect(fakeAccount.updatedDisplayName, isNull);

      // Enter valid name and save
      await tester.enterText(
        find.widgetWithText(TextFormField, 'A'),
        'Updated Name',
      );
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(fakeAccount.updatedDisplayName, 'Updated Name');
      expect(find.text('Profile updated.'), findsOneWidget);
    });

    testWidgets('Navigation rows open corresponding destinations',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeAuth.setUser(
        const AccountIdentity(
          id: 'user-1',
          email: 'user@example.com',
          fullName: 'Test Nav',
          role: AppRole.tourist,
          accessStatus: AccountAccessStatus.active,
          emailVerified: true,
        ),
      );

      await tester.pumpWidget(
        _buildProfileApp(
          auth: fakeAuth,
          account: fakeAccount,
          moderation: fakeModeration,
          launcher: fakeLauncher,
        ),
      );

      await tester.pumpAndSettle();

      // Tap Your Submissions
      final submissionsTile = find.text('Your submissions');
      await tester.ensureVisible(submissionsTile);
      await tester.tap(submissionsTile);
      await tester.pumpAndSettle();
      expect(find.text('My Submissions Mock'), findsOneWidget);
    });

    testWidgets(
        'Renders cleanly on small mobile viewport (360x640) without overflow',
        (tester) async {
      fakeAuth.setUser(
        const AccountIdentity(
          id: 'user-1',
          email: 'verylongemailaddressforthistest@example.com',
          fullName:
              'A Very Long Full Name That Might Wrap Around On Small Mobile Screens',
          role: AppRole.tourist,
          accessStatus: AccountAccessStatus.active,
          emailVerified: true,
        ),
      );

      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildProfileApp(
          auth: fakeAuth,
          account: fakeAccount,
          moderation: fakeModeration,
          launcher: fakeLauncher,
          screenSize: const Size(360, 640),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Avatar falls back to user initial when avatarUrl is missing or invalid',
        (tester) async {
      fakeAuth.setUser(
        const AccountIdentity(
          id: 'user-2',
          email: 'jane@example.com',
          fullName: 'Jane Doe',
          avatarUrl: 'https://example.com/broken_avatar.jpg',
          role: AppRole.tourist,
          accessStatus: AccountAccessStatus.active,
          emailVerified: true,
        ),
      );

      await tester.pumpWidget(
        _buildProfileApp(
          auth: fakeAuth,
          account: fakeAccount,
          moderation: fakeModeration,
          launcher: fakeLauncher,
        ),
      );
      await tester.pump();

      expect(find.text('J'), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
