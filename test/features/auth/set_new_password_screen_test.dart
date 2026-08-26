import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/auth_controller.dart';
import 'package:live_local/controllers/guide_controller.dart';
import 'package:live_local/controllers/itinerary_controller.dart';
import 'package:live_local/controllers/localeats_controller.dart';
import 'package:live_local/controllers/moderation_controller.dart';
import 'package:live_local/controllers/notification_controller.dart';
import 'package:live_local/controllers/review_controller.dart';
import 'package:live_local/controllers/spot_controller.dart';
import 'package:live_local/core/config/app_environment.dart';
import 'package:live_local/core/localization/app_localizations.dart';
import 'package:live_local/core/routing/protected_navigation.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/auth/presentation/session_gate.dart';
import 'package:live_local/features/auth/presentation/set_new_password_screen.dart';
import 'package:live_local/features/guides/data/demo_guide_repository.dart';
import 'package:live_local/features/itinerary/data/demo_saved_itinerary_repository.dart';
import 'package:live_local/features/moderation/data/demo_moderation_repository.dart';
import 'package:live_local/features/notifications/data/demo_notification_repository.dart';
import 'package:live_local/features/profile/data/demo_account_repository.dart';
import 'package:live_local/features/profile/presentation/account_controller.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/reviews/data/demo_review_repository.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';
import 'package:provider/provider.dart';

void main() {
  late DemoAuthRepository authRepository;
  late AuthController authController;
  late AccountController accountController;
  late SpotController spotController;
  late LocalEatsController localEatsController;
  late GuideController guideController;
  late ReviewController reviewController;
  late ItineraryController itineraryController;
  late NotificationController notificationController;
  late ModerationController moderationController;

  setUp(() async {
    authRepository = DemoAuthRepository();
    authController = AuthController(repository: authRepository);
    await authController.initialize();

    final accountRepository = DemoAccountRepository(authRepository);
    final spotRepository = DemoSpotRepository(authRepository);
    final localEatsRepository = DemoLocalEatsRepository(authRepository);
    final guideRepository = DemoGuideRepository(authRepository);
    final reviewRepository = DemoReviewRepository(authRepository);
    final itineraryRepository = DemoSavedItineraryRepository(authRepository);
    final notificationRepository = DemoNotificationRepository(authRepository);
    final moderationRepository = DemoModerationRepository(authRepository);

    accountController = AccountController(
      repository: accountRepository,
      authController: authController,
    );
    spotController = SpotController(repository: spotRepository);
    localEatsController = LocalEatsController(repository: localEatsRepository);
    guideController = GuideController(repository: guideRepository);
    reviewController = ReviewController(repository: reviewRepository);
    itineraryController = ItineraryController(repository: itineraryRepository);
    notificationController =
        NotificationController(repository: notificationRepository);
    moderationController =
        ModerationController(repository: moderationRepository);
  });

  Widget buildTestApp({required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppLocaleController()),
        ChangeNotifierProvider.value(value: authController),
        ChangeNotifierProvider.value(value: accountController),
        ChangeNotifierProvider.value(value: spotController),
        ChangeNotifierProvider.value(value: localEatsController),
        ChangeNotifierProvider.value(value: guideController),
        ChangeNotifierProvider.value(value: reviewController),
        ChangeNotifierProvider.value(value: itineraryController),
        ChangeNotifierProvider.value(value: notificationController),
        ChangeNotifierProvider.value(value: moderationController),
        Provider.value(value: AppConfiguration.demoForTesting()),
        Provider(create: (_) => ProtectedNavigation()),
      ],
      child: MaterialApp(
        routes: {
          '/login': (context) =>
              const Scaffold(body: Text('Login Screen Mock')),
        },
        home: child,
      ),
    );
  }

  testWidgets('SetNewPasswordScreen renders fields, toggles, and requirements',
      (tester) async {
    await tester.pumpWidget(
      buildTestApp(child: const SetNewPasswordScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set New Password'), findsOneWidget);
    expect(find.text('Create new password'), findsOneWidget);
    expect(find.text('New Password'), findsOneWidget);
    expect(find.text('Confirm New Password'), findsOneWidget);
    expect(find.text('Update Password'), findsOneWidget);
    expect(
      find.text(
          'Requirements: 10+ characters with at least one letter and one number.'),
      findsOneWidget,
    );

    expect(find.byTooltip('Show password'), findsOneWidget);
    expect(find.byTooltip('Show password confirmation'), findsOneWidget);
  });

  testWidgets('validates password requirements before submitting',
      (tester) async {
    await tester.pumpWidget(
      buildTestApp(child: const SetNewPasswordScreen()),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);

    // Enter short password
    await tester.enterText(fields.at(0), 'short1');
    await tester.enterText(fields.at(1), 'short1');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
    await tester.pump();

    expect(find.text('Use 10+ characters with a letter and number'),
        findsOneWidget);

    // Enter non-matching password
    await tester.enterText(fields.at(0), 'ValidPassword123!');
    await tester.enterText(fields.at(1), 'DifferentPassword123!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('successful password update shows feedback and completes',
      (tester) async {
    authRepository.triggerPasswordRecoveryForDemo('tourist@livelocal.com');
    await tester.pump();

    await tester.pumpWidget(
      buildTestApp(child: const SetNewPasswordScreen()),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'NewValidPassword123!');
    await tester.enterText(fields.at(1), 'NewValidPassword123!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
    await tester.pumpAndSettle();

    expect(find.text('Login Screen Mock'), findsOneWidget);
  });

  testWidgets(
      'SessionGate routes to SetNewPasswordScreen on passwordRecovery and normal UI on normal sign in',
      (tester) async {
    await tester.pumpWidget(
      buildTestApp(child: const SessionGate()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SetNewPasswordScreen), findsNothing);

    // Trigger password recovery
    authRepository.triggerPasswordRecoveryForDemo('tourist@livelocal.com');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SetNewPasswordScreen), findsOneWidget);
  });
}
