import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/review_controller.dart';
import '../features/reviews/domain/review.dart';

class ReviewTile extends StatelessWidget {
  final Review review;

  const ReviewTile({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ReviewController>();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(review.content),
            const Divider(),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    review.userVote == 1 ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: review.userVote == 1 ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => controller.toggleLike(review),
                ),
                Text('${review.likesCount}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                    review.userVote == -1 ? Icons.thumb_down : Icons.thumb_down_outlined,
                    color: review.userVote == -1 ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => controller.toggleDislike(review),
                ),
                Text('${review.dislikesCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}