import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/food_card.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../domain/entities/menu_category.dart';
import '../../domain/entities/menu_failure.dart';
import '../../domain/entities/menu_item.dart';
import '../viewmodels/menu_search_state.dart';
import '../viewmodels/menu_search_view_model.dart';
import '../widgets/search_filter_chips.dart';
import '../widgets/search_filter_sheet.dart';
import '../widgets/search_input_bar.dart';
import 'menu_item_detail_view.dart';

/// Search and filter screen (`specs/003-menu-search/contracts/search_screen_ui.md`).
///
/// With [openFilters] the filter sheet opens on arrival instead of focusing
/// the keyword field.
class MenuSearchView extends ConsumerStatefulWidget {
  const MenuSearchView({super.key, this.openFilters = false});

  final bool openFilters;

  @override
  ConsumerState<MenuSearchView> createState() => _MenuSearchViewState();
}

class _MenuSearchViewState extends ConsumerState<MenuSearchView> {
  final _keywordController = TextEditingController();
  final _scrollController = ScrollController();
  final _categories = ValueNotifier<List<MenuCategory>>(const []);

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      menuSearchViewModelProvider.select((state) => state.categories),
      (_, categories) => _categories.value = categories,
      fireImmediately: true,
    );
    if (widget.openFilters) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openFilters();
        }
      });
    }
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _scrollController.dispose();
    _categories.dispose();
    super.dispose();
  }

  MenuSearchViewModel get _viewModel =>
      ref.read(menuSearchViewModelProvider.notifier);

  Future<void> _openFilters() async {
    final filters = await showSearchFilterSheet(
      context,
      initial: ref.read(menuSearchViewModelProvider).filters,
      categories: _categories,
    );
    if (filters != null && mounted) {
      _viewModel.applyFilters(filters);
    }
  }

  void _clearKeyword() {
    _keywordController.clear();
    _viewModel.clearKeyword();
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
    ref.listen(menuSearchViewModelProvider.select((state) => state.notice), (
      _,
      notice,
    ) {
      if (notice == null) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_noticeMessage(notice))));
      _viewModel.clearNotice();
    });

    final state = ref.watch(menuSearchViewModelProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = AppSpacing.screenHorizontal(constraints.maxWidth);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    AppSpacing.lg,
                    padding,
                    AppSpacing.md,
                  ),
                  child: SearchInputBar(
                    controller: _keywordController,
                    autofocus: !widget.openFilters,
                    hasActiveFilters: !state.filters.isDefault,
                    onBack: () => Navigator.of(context).maybePop(),
                    onChanged: _viewModel.updateKeyword,
                    onSubmitted: _viewModel.submitKeyword,
                    onClear: _clearKeyword,
                    onFilterTap: _openFilters,
                  ),
                ),
                if (!state.filters.isDefault)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: SearchFilterChips(
                      filters: state.filters,
                      categoryName: state.selectedCategory?.name,
                      onRemoveCategory: _viewModel.removeCategoryFilter,
                      onRemoveAvailable: _viewModel.removeAvailableFilter,
                      onRemoveSortOrder: _viewModel.removeSortOrder,
                      onClearAll: _viewModel.clearFilters,
                      horizontalPadding: padding,
                    ),
                  ),
                if (state.isOffline)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      padding,
                      0,
                      padding,
                      AppSpacing.sm,
                    ),
                    child: const OfflineBanner(),
                  ),
                Expanded(child: _body(state, padding)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(MenuSearchState state, double padding) {
    final insets = EdgeInsets.symmetric(horizontal: padding);

    switch (state.status) {
      case MenuSearchStatus.loading:
        return SingleChildScrollView(
          padding: insets,
          child: const AppLoadingView.skeleton(
            semanticLabel: 'Đang tải thực đơn',
          ),
        );
      case MenuSearchStatus.error:
        return SingleChildScrollView(
          padding: insets,
          child: AppErrorView(
            message: _errorMessage(state.error),
            onRetry: _viewModel.retry,
          ),
        );
      case MenuSearchStatus.ready when state.results.isEmpty:
        return SingleChildScrollView(
          padding: insets,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: AppEmptyView(
            icon: Icons.search_off_rounded,
            title: 'Không tìm thấy món phù hợp',
            message: 'Thử từ khóa khác hoặc bỏ bộ lọc.',
            actionLabel: state.query.hasKeyword ? 'Xóa từ khóa' : null,
            onAction: _clearKeyword,
            secondaryActionLabel: state.filters.isDefault ? null : 'Xóa bộ lọc',
            onSecondaryAction: _viewModel.clearFilters,
          ),
        );
      case MenuSearchStatus.ready:
        final results = state.results;
        return ListView.separated(
          key: const PageStorageKey('menu-search-results'),
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: insets.copyWith(
            top: AppSpacing.sm,
            bottom: AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
          ),
          itemCount: results.length + 1,
          separatorBuilder: (_, index) =>
              SizedBox(height: index == 0 ? AppSpacing.md : AppSpacing.lg),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Text(
                '${results.length} món',
                key: const ValueKey('search-result-count'),
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textMuted,
                ),
              );
            }
            final item = results[index - 1];
            return FoodCard(
              key: ValueKey('search-result-${item.id}'),
              item: item,
              onTap: () => _openItem(item),
            );
          },
        );
    }
  }

  static String _noticeMessage(MenuSearchNotice notice) {
    return switch (notice) {
      MenuSearchNotice.categoryRemoved => 'Danh mục này không còn được bán',
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
