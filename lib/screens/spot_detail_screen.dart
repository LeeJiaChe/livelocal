import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/spot_model.dart';
import '../controllers/auth_controller.dart';
import '../controllers/itinerary_controller.dart';
import '../controllers/review_controller.dart';
import '../controllers/spot_controller.dart';
import '../constants/app_colors.dart';
import '../core/routing/protected_navigation.dart';
import '../features/moderation/presentation/content_report_dialog.dart';
import '../features/moderation/presentation/block_content_author_dialog.dart';
import '../features/moderation/presentation/moderation_controller.dart';
import '../features/reviews/presentation/widgets/review_text_widget.dart';
import '../features/reviews/presentation/widgets/review_photo_gallery.dart';
import '../features/reviews/presentation/widgets/review_photo_picker.dart';
import '../features/reviews/domain/review_repository.dart';
import '../shared/presentation/save_to_collection_sheet.dart';

class SpotDetailArguments {
  const SpotDetailArguments({required this.spot, this.pendingAction});

  final SpotModel spot;
  final SpotPendingAction? pendingAction;
}

class SpotPendingAction {
  const SpotPendingAction.save()
      : kind = 'save',
        reviewId = null;
  const SpotPendingAction.review()
      : kind = 'review',
        reviewId = null;
  const SpotPendingAction.upvote()
      : kind = 'upvote',
        reviewId = null;
  const SpotPendingAction.report(this.reviewId) : kind = 'report';
  const SpotPendingAction.reportSpot()
      : kind = 'report_spot',
        reviewId = null;
  const SpotPendingAction.blockReview(this.reviewId) : kind = 'block_review';
  const SpotPendingAction.blockSpotAuthor()
      : kind = 'block_spot_author',
        reviewId = null;

  final String kind;
  final String? reviewId;
}

class SpotDetailScreen extends StatefulWidget {
  final SpotModel spot;

  const SpotDetailScreen({
    super.key,
    required this.spot,
    this.pendingAction,
  });

  final SpotPendingAction? pendingAction;

  @override
  State<SpotDetailScreen> createState() => _SpotDetailScreenState();
}

class _SpotDetailScreenState extends State<SpotDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _scrollController = ScrollController();
  bool _showScrollToTop = false;
  double _userRating = 5.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context
          .read<ReviewController>()
          .loadReviews(spotId: widget.spot.id);
      if (!mounted || widget.pendingAction == null) return;
      switch (widget.pendingAction!.kind) {
        case 'save':
          await _requestSave();
          break;
        case 'review':
          _requestWriteReview();
          break;
        case 'upvote':
          await _requestUpvote();
          break;
        case 'report':
          final reviewId = widget.pendingAction!.reviewId;
          if (reviewId != null) {
            _requestReport(reviewId);
          }
          break;
        case 'report_spot':
          await _requestSpotReport();
          break;
        case 'block_review':
          final reviewId = widget.pendingAction!.reviewId;
          if (reviewId != null) {
            await _requestBlockAuthor('review', reviewId);
          }
          break;
        case 'block_spot_author':
          await _requestBlockAuthor('spot', widget.spot.id);
          break;
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final show = _scrollController.offset > 300;
    if (show != _showScrollToTop) {
      setState(() => _showScrollToTop = show);
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itineraryCtrl = Provider.of<ItineraryController>(context);
    final reviewCtrl = Provider.of<ReviewController>(context);
    final supportsUserBlocking =
        context.watch<ModerationController>().supportsUserBlocking;
    final spotController = context.watch<SpotController>();
    final matchingSpots =
        spotController.spots.where((spot) => spot.id == widget.spot.id);
    final currentSpot = matchingSpots.isEmpty ? null : matchingSpots.first;
    final upvoteCount = currentSpot?.upvoteCount ?? widget.spot.upvoteCount;
    final isUpvoted = currentSpot?.isUpvotedByCurrentUser ??
        widget.spot.isUpvotedByCurrentUser;

    final isSaved = itineraryCtrl.isSaved(
      spotId: widget.spot.id,
      googlePlaceId: widget.spot.googlePlaceId,
    );
    final spotReviews = reviewCtrl.getReviewsForSpot(widget.spot.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              tooltip: context.tr('Back to top'),
              backgroundColor: AppColors.primary,
              onPressed: _scrollToTop,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4)
                    ],
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: AppColors.primaryDark, size: 20),
                ),
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                tooltip: context.tr('Spot safety options'),
                iconColor: Colors.white,
                onSelected: (value) {
                  if (value == 'report') _requestSpotReport();
                  if (value == 'block') {
                    _requestBlockAuthor('spot', widget.spot.id);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'report',
                    child: Text('Report this spot'),
                  ),
                  if (supportsUserBlocking)
                    const PopupMenuItem(
                      value: 'block',
                      child: Text('Block contributor'),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  tooltip: context.tr(
                    isSaved ? 'Remove from saved' : 'Save place',
                  ),
                  onPressed: _requestSave,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
                      ],
                    ),
                    child: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: AppColors.primaryDark,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: widget.spot.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, size: 64, color: Colors.grey),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, size: 64, color: Colors.grey),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.spot.category,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          reviewCtrl
                              .getAverageRating(widget.spot.id, null)
                              .toStringAsFixed(1),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.spot.name,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.spot.address,
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: _requestUpvote,
                      icon: Icon(
                        isUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                      ),
                      label: Text(
                        isUpvoted
                            ? 'Upvoted · $upvoteCount'
                            : 'Upvote this spot · $upvoteCount',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('About this Local Spot',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      widget.spot.description,
                      style: TextStyle(
                          color: Colors.grey.shade800,
                          height: 1.5,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accent),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.access_time,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Best Visiting Time: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(text: widget.spot.bestTime),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Things to do / Order: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(text: widget.spot.thingsToDo),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Community Reviews',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _requestWriteReview,
                          icon:
                              const Icon(Icons.rate_review_outlined, size: 16),
                          label: Text(context.tr('Write Review')),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(120, 36),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Reviews List
                    if (spotReviews.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                            'No reviews yet. Be the first local visitor to share your review!'),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: spotReviews.length,
                        itemBuilder: (context, idx) {
                          final r = spotReviews[idx];
                          return Card(
                            elevation: 0,
                            color: AppColors.backgroundAlt,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: r.isAnonymous
                                            ? Colors.grey.shade600
                                            : AppColors.primary,
                                        child: Icon(
                                          r.isAnonymous
                                              ? Icons.person_outline
                                              : Icons.person,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              r.isAnonymous
                                                  ? context.tr('Anonymous')
                                                  : r.userName,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            if (r.isOwnedByCurrentUser &&
                                                r.isAnonymous)
                                              Text(
                                                context.tr('Your review'),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (i) => Icon(
                                            i < r.rating
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.amber,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                      if (!r.isOwnedByCurrentUser)
                                        PopupMenuButton<String>(
                                          constraints: const BoxConstraints(
                                            minWidth: 48,
                                            minHeight: 48,
                                          ),
                                          tooltip: context
                                              .tr('Review safety options'),
                                          onSelected: (value) {
                                            if (value == 'report') {
                                              _requestReport(r.id);
                                            }
                                            if (value == 'block') {
                                              _requestBlockAuthor(
                                                'review',
                                                r.id,
                                              );
                                            }
                                          },
                                          itemBuilder: (_) => [
                                            PopupMenuItem(
                                              value: 'report',
                                              child: Text(
                                                context.tr('Report review'),
                                              ),
                                            ),
                                            if (supportsUserBlocking)
                                              PopupMenuItem(
                                                value: 'block',
                                                child: Text(
                                                  context.tr(
                                                      'Block this reviewer'),
                                                ),
                                              ),
                                          ],
                                        ),
                                      if (r.isOwnedByCurrentUser)
                                        IconButton(
                                          constraints: const BoxConstraints(
                                              minWidth: 48, minHeight: 48),
                                          tooltip: context.tr('Edit review'),
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 18),
                                          onPressed: _requestWriteReview,
                                        ),
                                      if (r.isOwnedByCurrentUser)
                                        IconButton(
                                          constraints: const BoxConstraints(
                                              minWidth: 48, minHeight: 48),
                                          tooltip: context.tr('Delete review'),
                                          icon: const Icon(Icons.delete_outline,
                                              size: 18, color: Colors.grey),
                                          onPressed: () => _confirmDeleteReview(
                                            context,
                                            reviewCtrl,
                                            r.id,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ReviewTextWidget(text: r.comment),
                                  if (r.photos.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    ReviewPhotoGallery(photos: r.photos),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip: context.tr('Like review'),
                                        onPressed: () =>
                                            reviewCtrl.toggleReaction(r, 1),
                                        icon: Icon(r.userVote == 1
                                            ? Icons.thumb_up
                                            : Icons.thumb_up_outlined),
                                      ),
                                      Text('${r.likesCount}'),
                                      IconButton(
                                        tooltip: context.tr('Dislike review'),
                                        onPressed: () =>
                                            reviewCtrl.toggleReaction(r, -1),
                                        icon: Icon(r.userVote == -1
                                            ? Icons.thumb_down
                                            : Icons.thumb_down_outlined),
                                      ),
                                      Text('${r.dislikesCount}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestUpvote() async {
    final auth = context.read<AuthController>();
    if (!auth.canWrite) {
      context.read<ProtectedNavigation>().open(
            context,
            '/spot-detail',
            arguments: SpotDetailArguments(
              spot: widget.spot,
              pendingAction: const SpotPendingAction.upvote(),
            ),
          );
      return;
    }
    final controller = context.read<SpotController>();
    final saved = await controller.toggleUpvote(widget.spot.id);
    if (!mounted || saved) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(controller.errorMessage ?? 'Vote failed.')),
    );
  }

  Future<void> _requestSpotReport() async {
    final auth = context.read<AuthController>();
    if (!auth.canWrite) {
      context.read<ProtectedNavigation>().open(
            context,
            '/spot-detail',
            arguments: SpotDetailArguments(
              spot: widget.spot,
              pendingAction: const SpotPendingAction.reportSpot(),
            ),
          );
      return;
    }
    await showContentReportDialog(
      context,
      targetType: 'spot',
      targetId: widget.spot.id,
    );
  }

  Future<void> _requestBlockAuthor(
    String targetType,
    String targetId,
  ) async {
    final auth = context.read<AuthController>();
    if (!auth.canWrite) {
      context.read<ProtectedNavigation>().open(
            context,
            '/spot-detail',
            arguments: SpotDetailArguments(
              spot: widget.spot,
              pendingAction: targetType == 'review'
                  ? SpotPendingAction.blockReview(targetId)
                  : const SpotPendingAction.blockSpotAuthor(),
            ),
          );
      return;
    }
    final blocked = await showBlockContentAuthorDialog(
      context,
      targetType: targetType,
      targetId: targetId,
    );
    if (!mounted || !blocked) return;
    if (targetType == 'review') {
      await context.read<ReviewController>().loadReviews(
            spotId: widget.spot.id,
          );
    } else {
      await context.read<SpotController>().loadSpots();
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> _requestSave() async {
    await SaveToCollectionSheet.show(
      context,
      targetType: 'spot',
      targetId: widget.spot.id,
      placeName: widget.spot.name,
      spot: widget.spot,
    );
  }

  void _requestWriteReview() {
    if (!context.read<AuthController>().canWrite) {
      context.read<ProtectedNavigation>().open(
            context,
            '/spot-detail',
            arguments: SpotDetailArguments(
              spot: widget.spot,
              pendingAction: const SpotPendingAction.review(),
            ),
          );
      return;
    }
    _showWriteReviewSheet(context, context.read<ReviewController>());
  }

  void _requestReport(String reviewId) {
    if (!context.read<AuthController>().canWrite) {
      context.read<ProtectedNavigation>().open(
            context,
            '/spot-detail',
            arguments: SpotDetailArguments(
              spot: widget.spot,
              pendingAction: SpotPendingAction.report(reviewId),
            ),
          );
      return;
    }
    _showReportDialog(context, context.read<ReviewController>(), reviewId);
  }

  void _showWriteReviewSheet(
      BuildContext context, ReviewController reviewCtrl) {
    final ownReviews = reviewCtrl
        .getReviewsForSpot(widget.spot.id)
        .where((review) => review.isOwnedByCurrentUser);
    final existing = ownReviews.isEmpty ? null : ownReviews.single;
    var isAnonymous = existing?.isAnonymous ?? false;
    var photoInputs = existing?.photos
            .map((photo) => ReviewPhotoInput.existing(photo.path))
            .toList(growable: false) ??
        <ReviewPhotoInput>[];
    _commentCtrl.text = existing?.comment ?? '';
    _userRating = existing?.rating ?? 5;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        context.tr(existing == null
                            ? 'Write a review'
                            : 'Edit your review'),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(context.tr('Your Rating: '),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Row(
                          children: List.generate(5, (index) {
                            final ratingVal = index + 1.0;
                            return IconButton(
                              onPressed: () {
                                setModalState(() {
                                  _userRating = ratingVal;
                                });
                              },
                              icon: Icon(
                                index < _userRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 28,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            context.tr('Share your experience at this spot...'),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ReviewPhotoPicker(
                      existingPhotos: existing?.photos ?? const [],
                      onChanged: (photos) => photoInputs = photos,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.person_off_outlined),
                      title: Text(context.tr('Post anonymously')),
                      subtitle: Text(
                        context.tr('Hide my name from other LiveLocal users.'),
                      ),
                      value: isAnonymous,
                      onChanged: (val) =>
                          setModalState(() => isAnonymous = val),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        onPressed: () async {
                          if (_commentCtrl.text.trim().isEmpty) return;
                          try {
                            final saved = await reviewCtrl.addReview(
                              context,
                              spotId: widget.spot.id,
                              rating: _userRating,
                              comment: _commentCtrl.text.trim(),
                              isAnonymous: isAnonymous,
                              photos: photoInputs,
                            );
                            if (!saved) {
                              throw StateError('Review was not saved');
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Failed to submit review. Please try again.')),
                              );
                            }
                            return;
                          }
                          _commentCtrl.clear();
                          _userRating = 5.0;
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Review submitted! Thank you.')),
                            );
                          }
                        },
                        child: Text(context.tr('Submit Review'),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteReview(
    BuildContext context,
    ReviewController controller,
    String reviewId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete your review?'),
        content: const Text(
          'The rating aggregate will be updated immediately. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final removed = await controller.removeReview(reviewId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          removed
              ? 'Review deleted.'
              : controller.errorMessage ?? 'The review could not be deleted.',
        ),
      ),
    );
  }

  Future<void> _showReportDialog(
    BuildContext context,
    ReviewController controller,
    String reviewId,
  ) async {
    var reason = 'spam';
    final explanation = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Report this review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  decoration: InputDecoration(
                    labelText: context.tr('Reason'),
                    border: const OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'spam', child: Text('Spam')),
                    DropdownMenuItem(
                        value: 'harassment', child: Text('Harassment')),
                    DropdownMenuItem(
                        value: 'hate', child: Text('Hateful content')),
                    DropdownMenuItem(
                        value: 'dangerous', child: Text('Dangerous content')),
                    DropdownMenuItem(
                        value: 'misleading', child: Text('Misleading')),
                    DropdownMenuItem(
                        value: 'privacy', child: Text('Privacy concern')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => reason = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: explanation,
                  maxLength: 2000,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: context.tr('Explanation (optional)'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );

    if (submitted != true) return;

    final reported = await controller.reportReview(
      reviewId: reviewId,
      reason: reason,
      explanation: explanation.text.trim(),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          reported
              ? 'Thank you for keeping our community safe.'
              : controller.errorMessage ?? 'Failed to submit report.',
        ),
      ),
    );
  }
}
