import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/vnd_format.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/coming_soon_view.dart';
import '../../../../core/widgets/food_card.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../domain/entities/item_selection.dart';
import '../../domain/entities/menu_failure.dart';
import '../../domain/entities/menu_item.dart';
import '../viewmodels/menu_item_detail_state.dart';
import '../viewmodels/menu_item_detail_view_model.dart';
import '../widgets/item_option_section.dart';
import '../widgets/item_order_bar.dart';
import '../widgets/review_section.dart';

/// Food Details following the Food Ninja Product Detail frame
/// (`specs/004-food-details/contracts/food_details_ui.md`).
///
/// Opened by [menuItemId] from Home and search results.
class MenuItemDetailView extends ConsumerStatefulWidget {
  const MenuItemDetailView({super.key, required this.menuItemId});

  final String menuItemId;

  @override
  ConsumerState<MenuItemDetailView> createState() => _MenuItemDetailViewState();
}

class _MenuItemDetailViewState extends ConsumerState<MenuItemDetailView> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = menuItemDetailViewModelProvider(widget.menuItemId);
    ref.listen(provider.select((state) => state.notice), (_, notice) {
      if (notice == null) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_noticeMessage(notice))));
      ref.read(provider.notifier).clearNotice();
    });

    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);
    final item = state.item;
    final selection = state.selection;

    return Scaffold(
      bottomNavigationBar:
          state.status == MenuItemDetailStatus.ready && selection != null
          ? ItemOrderBar(
              canOrder: state.canOrder,
              quantity: selection.quantity,
              total: state.total,
              onDecrease: viewModel.decreaseQuantity,
              onIncrease: viewModel.increaseQuantity,
              onAddToCart: viewModel.addToCart,
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = AppSpacing.screenHorizontal(constraints.maxWidth);
          return switch (state.status) {
            MenuItemDetailStatus.ready when item != null && selection != null =>
              _Details(
                state: state,
                item: item,
                selection: selection,
                viewModel: viewModel,
                noteController: _noteController,
                horizontalPadding: padding,
                maxImageHeight: constraints.maxHeight * 0.45,
              ),
            MenuItemDetailStatus.unavailable => _Message(
              horizontalPadding: padding,
              child: AppEmptyView(
                title: 'Món này không còn được bán',
                actionLabel: 'Quay lại',
                onAction: () => Navigator.of(context).maybePop(),
              ),
            ),
            MenuItemDetailStatus.error => _Message(
              horizontalPadding: padding,
              child: AppErrorView(
                message: _errorMessage(state.error),
                onRetry: viewModel.retry,
              ),
            ),
            _ => _Message(
              horizontalPadding: padding,
              child: const AppLoadingView.skeleton(
                semanticLabel: 'Đang tải thông tin món',
              ),
            ),
          };
        },
      ),
    );
  }

  static String _noticeMessage(MenuItemDetailNotice notice) {
    return switch (notice) {
      MenuItemDetailNotice.optionsRemoved =>
        'Một số tùy chọn đã thay đổi, vui lòng chọn lại',
      MenuItemDetailNotice.reviewsNeedConnection =>
        'Cần kết nối mạng để tải thêm đánh giá',
      MenuItemDetailNotice.addToCartUnavailable => ComingSoonView.message,
    };
  }

  static String _errorMessage(MenuFailure? failure) {
    return switch (failure?.type) {
      MenuFailureType.unavailable =>
        'Không thể tải thông tin món. Hãy kiểm tra kết nối mạng.',
      MenuFailureType.permissionDenied => 'Bạn không có quyền xem món này.',
      _ => 'Không thể tải thông tin món.',
    };
  }
}

/// Non-ready states keep a back button above the message.
class _Message extends StatelessWidget {
  const _Message({required this.horizontalPadding, required this.child});

  final double horizontalPadding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          AppSpacing.lg,
          horizontalPadding,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(alignment: Alignment.centerLeft, child: _BackButton()),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.state,
    required this.item,
    required this.selection,
    required this.viewModel,
    required this.noteController,
    required this.horizontalPadding,
    required this.maxImageHeight,
  });

  /// How far the white content block overlaps the image.
  static const double overlap = 24;

  final MenuItemDetailState state;
  final MenuItem item;
  final ItemSelection selection;
  final MenuItemDetailViewModel viewModel;
  final TextEditingController noteController;
  final double horizontalPadding;
  final double maxImageHeight;

  @override
  Widget build(BuildContext context) {
    final range = item.priceRange;
    final canOrder = state.canOrder;

    return CustomScrollView(
      key: const PageStorageKey('menu-item-detail-scroll'),
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxImageHeight),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: SizedBox.expand(
                    child: item.imageUrl.isEmpty
                        ? const FoodImagePlaceholder()
                        : Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const FoodImagePlaceholder(),
                          ),
                  ),
                ),
              ),
              Positioned(
                left: horizontalPadding,
                top: AppSpacing.lg,
                child: const SafeArea(child: _BackButton()),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -overlap),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadii.dialog),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.xxl,
                horizontalPadding,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!item.isAvailable) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: SoldOutLabel(
                        text: 'Hết hàng – chưa thể thêm vào giỏ',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Text(item.name, style: AppTextStyles.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  _RatingSummary(item: item),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    formatVndRange(range.min, range.max),
                    style: AppTextStyles.price.copyWith(
                      fontSize: AppTextStyles.titleLarge.fontSize,
                      height: AppTextStyles.titleLarge.height,
                    ),
                  ),
                  if (state.isOffline) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const OfflineBanner(),
                  ],
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _Description(text: item.description),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  ItemOptionSection(
                    item: item,
                    selection: selection,
                    enabled: canOrder,
                    onSizeSelected: viewModel.selectSize,
                    onToppingToggled: viewModel.toggleTopping,
                  ),
                  _NoteField(
                    controller: noteController,
                    enabled: canOrder,
                    onChanged: viewModel.updateNote,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ReviewSection(
                    reviews: state.reviews,
                    reviewCount: item.reviewCount,
                    onLoadMore: viewModel.loadMoreReviews,
                    onRetry: viewModel.retryReviews,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [AppShadows.card],
      ),
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          key: const ValueKey('detail-back'),
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context).maybePop(),
          child: const SizedBox.square(
            dimension: AppSpacing.minTouchTarget,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: AppColors.foodAccentDark,
              semanticLabel: 'Quay lại',
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('detail-rating'),
      spacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (item.hasRating) RatingStars(rating: item.ratingAverage),
        Text(
          item.hasRating
              ? '${item.ratingAverage.toStringAsFixed(1).replaceAll('.', ',')} '
                    '(${item.reviewCount} đánh giá)'
              : 'Chưa có đánh giá',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Description extends StatefulWidget {
  const _Description({required this.text});

  static const int collapsedLines = 6;

  final String text;

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    const style = AppTextStyles.bodyLarge;
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _Description.collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: _expanded ? null : _Description.collapsedLines,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
            if (overflows)
              TextButton(
                key: const ValueKey('detail-description-toggle'),
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryEnd,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, AppSpacing.minTouchTarget),
                  textStyle: AppTextStyles.labelLarge,
                ),
                child: Text(_expanded ? 'Thu gọn' : 'Xem thêm'),
              ),
          ],
        );
      },
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: const BorderSide(color: AppColors.border),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: const Text('Ghi chú', style: AppTextStyles.titleMedium),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const ValueKey('detail-note'),
          controller: controller,
          enabled: enabled,
          minLines: 2,
          maxLines: 4,
          maxLength: ItemSelection.maxNoteLength,
          onChanged: onChanged,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Ví dụ: ít đá, không hành',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(
                color: AppColors.primaryEnd,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
