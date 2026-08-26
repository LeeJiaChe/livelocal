import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:live_local/core/localization/app_localizations.dart';

import '../../../../models/review_model.dart';

class ReviewPhotoGallery extends StatelessWidget {
  const ReviewPhotoGallery({super.key, required this.photos});

  final List<ReviewPhotoModel> photos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    return Semantics(
      label: '${photos.length} review photos',
      child: SizedBox(
        height: photos.length == 1 ? 190 : 128,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final photo = photos[index];
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _openGallery(context, index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: photos.length == 1 ? 260 : 150,
                  child: photo.bytes != null
                      ? Image.memory(photo.bytes!, fit: BoxFit.cover)
                      : CachedNetworkImage(
                          imageUrl: photo.url,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const ColoredBox(
                            color: Color(0xFFE4DACB),
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openGallery(BuildContext context, int initialPage) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialPage),
              itemCount: photos.length,
              itemBuilder: (_, index) {
                final photo = photos[index];
                return InteractiveViewer(
                  child: Center(
                    child: photo.bytes != null
                        ? Image.memory(photo.bytes!, fit: BoxFit.contain)
                        : CachedNetworkImage(
                            imageUrl: photo.url,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white,
                            ),
                          ),
                  ),
                );
              },
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  tooltip: context.tr('Close'),
                  color: Colors.white,
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
