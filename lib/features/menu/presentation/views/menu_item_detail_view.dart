import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/vnd_format.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/food_card.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../auth/presentation/views/login_view.dart';
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
class MenuItemDetailView extends ConsumerWidget {
  const MenuItemDetailView({super.key, required this.menuItemId});

  final String menuItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = menuItemDetailViewModelProvider(menuItemId);
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
    final signedIn = ref.watch(authStateProvider).value != null;
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
              onAddToCart: signedIn
                  ? viewModel.addToCart
                  : () => _signInThenAddToCart(context, viewModel),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = AppSpacing.screenHorizontalFor(constraints.maxWidth);
          return switch (state.status) {
            MenuItemDetailStatus.ready when item != null && selection != null =>
              _Details(
                state: state,
                item: item,
                selection: selection,
                viewModel: viewModel,
                showCartButton: signedIn,
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

  /// Guests must sign in before using the cart. Login returns here with
  /// `true` on success, and the chosen item is then added.
  static Future<void> _signInThenAddToCart(
    BuildContext context,
    MenuItemDetailViewModel viewModel,
  ) async {
    // AppRoutes builds untyped routes, so pushNamed must stay untyped too:
    // pushNamed<bool> would fail to cast the route and never open Login.
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.login,
      arguments: const LoginArgs(returnToCaller: true),
    );
    if (result == true) {
      await viewModel.addToCart();
    }
  }

  static String _noticeMessage(MenuItemDetailNotice notice) {
    return switch (notice) {
      MenuItemDetailNotice.optionsRemoved =>
        'Một số tùy chọn đã thay đổi, vui lòng chọn lại',
      MenuItemDetailNotice.reviewsNeedConnection =>
        'Cần kết nối mạng để tải thêm đánh giá',
      MenuItemDetailNotice.addedToCart => 'Đã thêm món vào giỏ hàng',
      MenuItemDetailNotice.addToCartFailed =>
        'Không thể thêm món vào giỏ hàng. Vui lòng thử lại.',
      MenuItemDetailNotice.addToCartUnavailable =>
        'Không thể thêm món vào giỏ hàng. Vui lòng thử lại.',
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
          AppSpacing.p16,
          horizontalPadding,
          AppSpacing.p24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(alignment: Alignment.centerLeft, child: _BackButton()),
            const SizedBox(height: AppSpacing.p16),
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
    required this.showCartButton,
    required this.horizontalPadding,
    required this.maxImageHeight,
  });

  /// How far the white content block overlaps the image.
  static const double overlap = 24;

  final MenuItemDetailState state;
  final MenuItem item;
  final ItemSelection selection;
  final MenuItemDetailViewModel viewModel;

  /// The cart shortcut is only for signed-in users.
  final bool showCartButton;
  final double horizontalPadding;
  final double maxImageHeight;

  @override
  Widget build(BuildContext context) {
    final range = item.priceRange;
    final canOrder = state.canOrder;
    final imageHeight = (MediaQuery.sizeOf(context).width * 3 / 4).clamp(
      0.0,
      maxImageHeight,
    );

    return CustomScrollView(
      key: const PageStorageKey('menu-item-detail-scroll'),
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: imageHeight,
                child: item.imageUrl.isEmpty
                    ? const FoodImagePlaceholder()
                    : Image.network(
                        item.imageUrl,
                        width: double.infinity,
                        height: imageHeight,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const FoodImagePlaceholder(),
                      ),
              ),
              Positioned(
                left: horizontalPadding,
                top: AppSpacing.p16,
                child: const SafeArea(child: _BackButton()),
              ),
              if (showCartButton)
                Positioned(
                  right: horizontalPadding,
                  top: AppSpacing.p16,
                  child: SafeArea(
                    child: _CartButton(
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.cart),
                    ),
                  ),
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
                AppSpacing.p24,
                horizontalPadding,
                AppSpacing.p24,
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
                    const SizedBox(height: AppSpacing.p12),
                  ],
                  Text(item.name, style: AppTextStyles.headlineMedium),
                  const SizedBox(height: AppSpacing.p8),
                  _RatingSummary(item: item),
                  const SizedBox(height: AppSpacing.p12),
                  Text(
                    formatVndRange(range.min, range.max),
                    style: AppTextStyles.price.copyWith(
                      fontSize: AppTextStyles.titleLarge.fontSize,
                      height: AppTextStyles.titleLarge.height,
                    ),
                  ),
                  if (state.isOffline) ...[
                    const SizedBox(height: AppSpacing.p16),
                    const OfflineBanner(),
                  ],
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.p16),
                    _Description(text: item.description),
                  ],
                  const SizedBox(height: AppSpacing.p20),
                  ItemOptionSection(
                    item: item,
                    selection: selection,
                    enabled: canOrder,
                    onSizeSelected: viewModel.selectSize,
                    onToppingToggled: viewModel.toggleTopping,
                  ),
                  const SizedBox(height: AppSpacing.p24),
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

class _CartButton extends StatelessWidget {
  const _CartButton({required this.onTap});

  final VoidCallback onTap;

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
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox.square(
            dimension: AppSpacing.minTouchTarget,
            child: Icon(
              Icons.shopping_cart_rounded,
              size: 20,
              color: AppColors.primaryEnd,
              semanticLabel: 'Mở giỏ hàng',
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
      spacing: AppSpacing.p8,
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
