import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/food_card.dart';

/// Full-screen viewer for the images of one review: swipe between them,
/// pinch to zoom, close to return to the same place.
Future<void> showReviewImageViewer(
  BuildContext context, {
  required List<String> imageUrls,
  required int initialIndex,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.textPrimary,
    builder: (_) =>
        _ReviewImageViewer(imageUrls: imageUrls, initialIndex: initialIndex),
  );
}

class _ReviewImageViewer extends StatefulWidget {
  const _ReviewImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<_ReviewImageViewer> createState() => _ReviewImageViewerState();
}

class _ReviewImageViewerState extends State<_ReviewImageViewer> {
  late final _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: AppColors.textPrimary,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              key: const ValueKey('review-image-pages'),
              controller: _controller,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (_, index) => InteractiveViewer(
                child: Center(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.square(
                      dimension: 200,
                      child: FoodImagePlaceholder(),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.p8,
              left: AppSpacing.p16,
              child: Text(
                '${_index + 1}/${widget.imageUrls.length}',
                key: const ValueKey('review-image-index'),
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.surface,
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: AppSpacing.p8,
              child: IconButton(
                key: const ValueKey('review-image-close'),
                tooltip: 'Đóng',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: AppColors.surface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
