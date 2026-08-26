import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/features/moderation/domain/moderation_repository.dart';
import 'package:live_local/features/moderation/presentation/moderation_controller.dart';

void main() {
  test('blocking refreshes the private list and unblock restores it', () async {
    final repository = _FakeModerationRepository();
    final controller = ModerationController(repository: repository);

    expect(controller.supportsUserBlocking, isTrue);
    expect(
      await controller.blockContentAuthor(
        targetType: 'review',
        targetId: 'review-1',
      ),
      isTrue,
    );
    expect(controller.lastBlock?.userId, 'author-1');
    expect(controller.blockedUsers, hasLength(1));

    expect(await controller.unblockUser('author-1'), isTrue);
    expect(controller.blockedUsers, isEmpty);
  });

  test('anonymous reviewer block uses opaque id and generic name', () async {
    final repository = _FakeModerationRepository();
    final controller = ModerationController(repository: repository);

    expect(
      await controller.blockContentAuthor(
        targetType: 'review',
        targetId: 'anon-review-99',
      ),
      isTrue,
    );
    expect(controller.lastBlock?.userId, 'opaque-block-uuid-1234');
    expect(controller.lastBlock?.displayName, 'Anonymous reviewer');
    expect(controller.blockedUsers, hasLength(1));
    expect(controller.blockedUsers.first.displayName, 'Anonymous reviewer');

    expect(await controller.unblockUser('opaque-block-uuid-1234'), isTrue);
    expect(controller.blockedUsers, isEmpty);
  });

  test('unsupported adapters fail honestly instead of simulating a block',
      () async {
    final repository = _FakeModerationRepository(supportsBlocking: false);
    final controller = ModerationController(repository: repository);

    expect(
      await controller.blockContentAuthor(
        targetType: 'review',
        targetId: 'review-1',
      ),
      isFalse,
    );
    expect(controller.errorMessage, contains('unavailable'));
    expect(repository.blockCalls, 0);
  });
}

class _FakeModerationRepository implements ModerationRepository {
  _FakeModerationRepository({this.supportsBlocking = true});

  final bool supportsBlocking;
  final List<BlockedUser> _blocked = [];
  int blockCalls = 0;

  @override
  bool get supportsUserBlocking => supportsBlocking;

  @override
  Future<UserBlockReceipt> blockContentAuthor({
    required String targetType,
    required String targetId,
  }) async {
    blockCalls += 1;
    final isAnon = targetId.contains('anon');
    final blockId = isAnon ? 'opaque-block-uuid-1234' : 'author-1';
    final name = isAnon ? 'Anonymous reviewer' : 'Test Author';
    _blocked
      ..clear()
      ..add(
        BlockedUser(
          userId: blockId,
          displayName: name,
          blockedAt: DateTime.utc(2026, 8, 5),
        ),
      );
    return UserBlockReceipt(
      userId: blockId,
      displayName: name,
    );
  }

  @override
  Future<List<BlockedUser>> listBlockedUsers() async => List.of(_blocked);

  @override
  Future<void> unblockUser(String userId) async {
    _blocked.removeWhere((blocked) => blocked.userId == userId);
  }

  @override
  Future<ModerationReceipt> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
    String? explanation,
    required bool hideForReporter,
  }) async {
    return const ModerationReceipt(id: 'case-1', status: 'pending', version: 1);
  }
}
