import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/coming_soon_view.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../domain/entities/menu_failure.dart';
import '../../domain/entities/menu_item.dart';
import '../viewmodels/home_menu_state.dart';
import '../viewmodels/home_menu_view_model.dart';
import '../widgets/category_card_list.dart';
import '../widgets/home_header.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/menu_section_list.dart';
import '../widgets/popular_section.dart';
import '../widgets/restaurant_banner.dart';
import 'menu_item_detail_view.dart';
import 'menu_search_view.dart';

/// Home screen following the Food Ninja Home frame
/// (`specs/002-browse-menu/contracts/home_screen_ui.md`).
class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  /// Distance from the end of the list at which the next page is requested.
  static const double loadMoreThreshold = 400;

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final _scrollController = ScrollController();
  final _categoriesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.extentAfter < HomeView.loadMoreThreshold) {
      ref.read(homeMenuViewModelProvider.notifier).loadMore();
    }
  }

  void _selectCategory(String? categoryId) {
    ref.read(homeMenuViewModelProvider.notifier).selectCategory(categoryId);
    // Bring the category cards back into view if the list was scrolled past.
    _showCategories(ScrollPositionAlignmentPolicy.keepVisibleAtStart);
  }

  void _showCategories([
    ScrollPositionAlignmentPolicy policy =
        ScrollPositionAlignmentPolicy.explicit,
  ]) {
    final categoriesContext = _categoriesKey.currentContext;
    if (categoriesContext == null) {
      return;
    }
    Scrollable.ensureVisible(
      categoriesContext,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignmentPolicy: policy,
    );
  }

  void _showUnavailableFeature() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(ComingSoonView.message)));
  }

  /// Opens search over the whole screen, hiding the shell's tab bar.
  void _openSearch({bool openFilters = false}) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => MenuSearchView(openFilters: openFilters),
      ),
    );
  }

  void _openItem(MenuItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MenuItemDetailView(menuItemId: item.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(homeMenuViewModelProvider.select((state) => state.notice), (
      _,
      notice,
    ) {
      if (notice == null) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_noticeMessage(notice))));
      ref.read(homeMenuViewModelProvider.notifier).clearNotice();
    });

    final state = ref.watch(homeMenuViewModelProvider);
    final viewModel = ref.read(homeMenuViewModelProvider.notifier);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = AppSpacing.screenHorizontalFor(constraints.maxWidth);
          final insets = EdgeInsets.symmetric(horizontal: padding);

          return CustomScrollView(
            key: const PageStorageKey('home-menu-scroll'),
            controller: _scrollController,
            slivers: [
              SliverSafeArea(
                bottom: false,
                sliver: SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    AppSpacing.p20,
                    padding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HomeHeader(onNotificationsTap: _showUnavailableFeature),
                        const SizedBox(height: AppSpacing.p20),
                        HomeSearchBar(
                          onSearchTap: _openSearch,
                          onFilterTap: () => _openSearch(openFilters: true),
                        ),
                        const SizedBox(height: AppSpacing.p20),
                        if (state.isOffline) ...[
                          const OfflineBanner(),
                          const SizedBox(height: AppSpacing.p16),
                        ],
                        RestaurantBanner(onViewMenu: _showCategories),
                        const SizedBox(height: AppSpacing.p24),
                      ],
                    ),
                  ),
                ),
              ),
              ..._body(state, viewModel, padding),
              SliverPadding(
                padding: insets,
                sliver: const SliverToBoxAdapter(
                  child: SafeArea(
                    top: false,
                    child: SizedBox(height: AppSpacing.p24),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _body(
    HomeMenuState state,
    HomeMenuViewModel viewModel,
    double padding,
  ) {
    final insets = EdgeInsets.symmetric(horizontal: padding);

    switch (state.status) {
      case HomeMenuStatus.loading:
        return [
          SliverPadding(
            padding: insets,
            sliver: const SliverToBoxAdapter(
              child: AppLoadingView.skeleton(
                semanticLabel: 'Đang tải thực đơn',
              ),
            ),
          ),
        ];
      case HomeMenuStatus.error:
        return [
          SliverPadding(
            padding: insets,
            sliver: SliverToBoxAdapter(
              child: AppErrorView(
                message: _errorMessage(state.error),
                onRetry: viewModel.retry,
              ),
            ),
          ),
        ];
      case HomeMenuStatus.empty:
        return [
          SliverPadding(
            padding: insets,
            sliver: const SliverToBoxAdapter(
              child: AppEmptyView(
                title: 'Thực đơn chưa sẵn sàng',
                message: 'Nhà hàng chưa đăng món nào. Vui lòng quay lại sau.',
              ),
            ),
          ),
        ];
      case HomeMenuStatus.data:
        return [
          SliverToBoxAdapter(
            key: _categoriesKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: insets,
                  child: Semantics(
                    header: true,
                    child: const Text(
                      'Danh mục',
                      style: AppTextStyles.titleLarge,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.p8),
                CategoryCardList(
                  categories: state.categories,
                  selectedCategoryId: state.selectedCategoryId,
                  onSelected: _selectCategory,
                  horizontalPadding: padding,
                ),
              ],
            ),
          ),
          // A selected category shows only its own items (US2-5).
          if (state.isAllSelected && state.popular.isNotEmpty)
            SliverPadding(
              padding: insets.copyWith(top: AppSpacing.p8),
              sliver: SliverToBoxAdapter(
                child: PopularSection(
                  items: state.popular,
                  onItemTap: _openItem,
                ),
              ),
            ),
          if (state.isSelectedCategoryEmpty)
            SliverPadding(
              padding: insets,
              sliver: SliverToBoxAdapter(
                child: AppEmptyView(
                  title: 'Danh mục này chưa có món',
                  actionLabel: 'Xem tất cả món',
                  onAction: () => _selectCategory(null),
                ),
              ),
            )
          else
            SliverPadding(
              padding: insets.copyWith(
                top: state.isAllSelected ? 0 : AppSpacing.p16,
              ),
              sliver: MenuSectionList(
                sections: state.sections,
                showHeaders: state.isAllSelected,
                isLoadingMore: state.isLoadingMore,
                onItemTap: _openItem,
              ),
            ),
        ];
    }
  }

  static String _noticeMessage(HomeMenuNotice notice) {
    return switch (notice) {
      HomeMenuNotice.categoryRemoved => 'Danh mục này không còn được bán',
      HomeMenuNotice.loadMoreFailed =>
        'Không tải thêm được món. Vui lòng thử lại.',
    };
  }

  static String _errorMessage(MenuFailure? failure) {
    return switch (failure?.type) {
      MenuFailureType.unavailable =>
        'Không thể tải thực đơn. Hãy kiểm tra kết nối mạng.',
      MenuFailureType.permissionDenied =>
        'Bạn không có quyền xem thực đơn này.',
      _ => 'Đã có lỗi khi tải thực đơn.',
    };
  }
}
