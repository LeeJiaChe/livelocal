import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:image_picker/image_picker.dart';
import 'package:live_local/core/localization/localized_text.dart';

import '../../../../models/review_model.dart';
import '../../domain/review_repository.dart';

class ReviewPhotoPicker extends StatefulWidget {
  const ReviewPhotoPicker({
    super.key,
    required this.existingPhotos,
    required this.onChanged,
  });

  final List<ReviewPhotoModel> existingPhotos;
  final ValueChanged<List<ReviewPhotoInput>> onChanged;

  @override
  State<ReviewPhotoPicker> createState() => _ReviewPhotoPickerState();
}

class _ReviewPhotoPickerState extends State<ReviewPhotoPicker> {
  static const _maxPhotos = 3;
  static const _maxBytes = 6 * 1024 * 1024;
  late final List<_PhotoDraft> _photos;

  @override
  void initState() {
    super.initState();
    _photos = widget.existingPhotos
        .map(
          (photo) => _PhotoDraft(
            existingPath: photo.path,
            previewUrl: photo.url,
          ),
        )
        .toList();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
  }

  Future<void> _pick() async {
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) return;
    try {
      final selected = await ImagePicker().pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
      );
      if (!mounted || selected.isEmpty) return;
      final accepted = <_PhotoDraft>[];
      for (final file in selected.take(remaining)) {
        final bytes = await file.readAsBytes();
        final mimeType = _allowedMime(file);
        if (mimeType == null || bytes.isEmpty || bytes.length > _maxBytes) {
          if (mounted) {
            _message(
              'Use JPG, PNG, or WebP photos smaller than 6 MB each.',
            );
          }
          continue;
        }
        accepted.add(_PhotoDraft(bytes: bytes, mimeType: mimeType));
      }
      if (!mounted || accepted.isEmpty) return;
      setState(() => _photos.addAll(accepted));
      _notify();
    } catch (_) {
      if (mounted) _message('Review photos could not be opened. Try again.');
    }
  }

  String? _allowedMime(XFile file) {
    final reported = file.mimeType?.toLowerCase();
    if (reported == 'image/jpeg' ||
        reported == 'image/png' ||
        reported == 'image/webp') {
      return reported;
    }
    final name = file.name.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return null;
  }

  void _removeAt(int index) {
    setState(() => _photos.removeAt(index));
    _notify();
  }

  void _notify() {
    widget.onChanged(
      _photos
          .map(
            (photo) => photo.existingPath != null
                ? ReviewPhotoInput.existing(photo.existingPath!)
                : ReviewPhotoInput.upload(
                    bytes: photo.bytes!,
                    mimeType: photo.mimeType!,
                  ),
          )
          .toList(growable: false),
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review photos',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Text('Optional · up to 3 original photos'),
                ],
              ),
            ),
            Text('${_photos.length}/$_maxPhotos'),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _photos.length + (_photos.length < _maxPhotos ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == _photos.length) {
                return _AddPhotoButton(onTap: _pick);
              }
              final photo = _photos[index];
              return SizedBox(
                width: 104,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: photo.bytes != null
                          ? Image.memory(photo.bytes!, fit: BoxFit.cover)
                          : CachedNetworkImage(
                              imageUrl: photo.previewUrl ?? '',
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const ColoredBox(
                                color: Color(0xFFE4DACB),
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: IconButton.filled(
                        tooltip: context.tr('Remove photo'),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _removeAt(index),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Only upload photos you own or have permission to publish. JPG, PNG, or WebP; 6 MB each.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 104,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined),
              SizedBox(height: 4),
              Text('Add photo', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class _PhotoDraft {
  const _PhotoDraft({
    this.existingPath,
    this.previewUrl,
    this.bytes,
    this.mimeType,
  });

  final String? existingPath;
  final String? previewUrl;
  final Uint8List? bytes;
  final String? mimeType;
}
