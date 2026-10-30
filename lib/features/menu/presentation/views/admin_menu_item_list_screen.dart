import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/admin_drawer.dart';
import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/viewmodels/category_management_view_model.dart';
import '../../domain/entities/menu_item.dart';
import '../viewmodels/admin_menu_view_model.dart';
import '../widgets/admin_menu_item_card.dart';
import 'menu_item_form_screen.dart';

class AdminMenuItemListScreen extends ConsumerStatefulWidget {
  const AdminMenuItemListScreen({this.initialCategoryId, super.key});

  final String? initialCategoryId;

  @override
  ConsumerState<AdminMenuItemListScreen> createState() =>
      _AdminMenuItemListScreenState();
}

class _AdminMenuItemListScreenState
    extends ConsumerState<AdminMenuItemListScreen> {
  late String? _categoryId;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final items = ref.watch(adminMenuItemsProvider(_categoryId));
    final action = ref.watch(adminMenuViewModelProvider);

    ref.listen(adminMenuViewModelProvider, (previous, next) {
      if (next.hasError && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The menu item could not be updated.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      drawer: const AdminDrawer(currentDestination: AdminDestination.menuItems),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360
                ? AppSpacing.md
                : AppSpacing.xl;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.md,
                    horizontalPadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBar(
                        onBack: () => Navigator.of(context).pop(),
                        onRefresh: () {
                          ref.invalidate(adminMenuItemsProvider(_categoryId));
                          ref.invalidate(categoriesProvider);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text('Menu Items', style: AppTextStyles.headlineLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Manage food, drinks, visibility, and daily availability.',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      OutlinedButton.icon(
                        key: const ValueKey('add-menu-item'),
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add new menu item'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      items.maybeWhen(
                        data: (data) => _MenuSummary(items: data),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _SearchField(
                                onChanged: (value) =>
                                    setState(() => _query = value.trim()),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _CategoryFilterMenu(
                              categories: categories.value ?? const [],
                              selectedId: _categoryId,
                              isLoading: categories.isLoading,
                              onSelected: (value) =>
                                  setState(() => _categoryId = value),
                            ),
                          ],
                        ),
                      ),
                      if (_categoryId != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Builder(
                          builder: (context) {
                            final currentCategoryName = categories.value
                                ?.firstWhere(
                                  (c) => c.id == _categoryId,
                                  orElse: () => Category(
                                    id: _categoryId!,
                                    name: 'Category',
                                    imageUrl: '',
                                    sortOrder: 0,
                                    isPublished: true,
                                  ),
                                )
                                .name;
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Chip(
                                key: const ValueKey('active-category-chip'),
                                avatar: const Icon(
                                  Icons.tune_rounded,
                                  size: 14,
                                  color: AppColors.primaryEnd,
                                ),
                                label: Text(
                                  'Category: ${currentCategoryName ?? ''}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primaryEnd,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor: AppColors.primarySoft,
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.pill,
                                  ),
                                ),
                                deleteIcon: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.primaryEnd,
                                ),
                                onDeleted: () =>
                                    setState(() => _categoryId = null),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: items.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryEnd,
                            ),
                          ),
                          error: (error, _) => _ErrorState(
                            onRetry: () => ref.invalidate(
                              adminMenuItemsProvider(_categoryId),
                            ),
                          ),
                          data: (data) => _MenuList(
                            items: data,
                            categories: categories.value ?? const [],
                            query: _query,
                            actionsEnabled: !action.isLoading,
                            onAvailabilityChanged: (item, value) => ref
                                .read(adminMenuViewModelProvider.notifier)
                                .setAvailability(item, value),
                            onPublishedChanged: (item, value) => ref
                                .read(adminMenuViewModelProvider.notifier)
                                .setPublished(item, value),
                            onEdit: _openForm,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openForm([MenuItem? item]) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MenuItemFormScreen(
          item: item,
          initialCategoryId: item?.categoryId ?? _categoryId,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onRefresh});

  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (Navigator.canPop(context)) ...[
          IconButton(
            tooltip: 'Back to categories',
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceMuted,
              minimumSize: const Size(44, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.medium),
              ),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Builder(
          builder: (scaffoldContext) => IconButton(
            key: const ValueKey('admin-drawer-button'),
            tooltip: 'Open navigation menu',
            onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primarySoft,
              foregroundColor: AppColors.primaryEnd,
              minimumSize: const Size(44, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.medium),
              ),
            ),
            icon: const Icon(Icons.menu_rounded),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ngô Chicken', style: AppTextStyles.titleMedium),
              Text('Menu catalogue', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh menu items',
          onPressed: onRefresh,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceMuted,
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
          ),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _MenuSummary extends StatelessWidget {
  const _MenuSummary({required this.items});

  final List<MenuItem> items;

  @override
  Widget build(BuildContext context) {
    final available = items.where((item) => item.isAvailable).length;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Text(
        '${items.length} items · $available available',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primaryEnd,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.input),
        boxShadow: const [AppShadows.card],
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'Search food or drinks',
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primaryEnd),
        ),
      ),
    );
  }
}

class _CategoryFilterMenu extends StatelessWidget {
  const _CategoryFilterMenu({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    this.isLoading = false,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isFiltered = selectedId != null;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: isFiltered ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.input),
          boxShadow: const [AppShadows.card],
          border: isFiltered
              ? Border.all(color: AppColors.primaryEnd, width: 1.5)
              : null,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: PopupMenuButton<String?>(
            key: const ValueKey('category-filter-button'),
            tooltip: 'Filter by category',
            enabled: !isLoading,
            initialValue: selectedId,
            onSelected: onSelected,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            color: AppColors.surface,
            elevation: 8,
            icon: Badge(
              isLabelVisible: isFiltered,
              backgroundColor: AppColors.primaryEnd,
              smallSize: 8,
              child: Icon(
                Icons.tune_rounded,
                color: isFiltered
                    ? AppColors.primaryEnd
                    : AppColors.textPrimary,
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem<String?>(
                key: const ValueKey('category-filter-all'),
                value: null,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'All',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: selectedId == null
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selectedId == null
                              ? AppColors.primaryEnd
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (selectedId == null)
                      const Icon(
                        Icons.check_rounded,
                        color: AppColors.primaryEnd,
                        size: 18,
                      ),
                  ],
                ),
              ),
              if (categories.isNotEmpty) const PopupMenuDivider(),
              for (final category in categories)
                PopupMenuItem<String?>(
                  key: ValueKey('category-filter-${category.id}'),
                  value: category.id,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.name,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: selectedId == category.id
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selectedId == category.id
                                ? AppColors.primaryEnd
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (selectedId == category.id)
                        const Icon(
                          Icons.check_rounded,
                          color: AppColors.primaryEnd,
                          size: 18,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuList extends StatelessWidget {
  const _MenuList({
    required this.items,
    required this.categories,
    required this.query,
    required this.actionsEnabled,
    required this.onAvailabilityChanged,
    required this.onPublishedChanged,
    required this.onEdit,
  });

  final List<MenuItem> items;
  final List<Category> categories;
  final String query;
  final bool actionsEnabled;
  final void Function(MenuItem, bool) onAvailabilityChanged;
  final void Function(MenuItem, bool) onPublishedChanged;
  final ValueChanged<MenuItem> onEdit;

  @override
  Widget build(BuildContext context) {
    final normalized = query.toLowerCase();
    final visible = normalized.isEmpty
        ? items
        : items
              .where((item) => item.name.toLowerCase().contains(normalized))
              .toList(growable: false);
    if (visible.isEmpty) {
      return Center(
        child: Text(
          items.isEmpty
              ? 'No menu items in this category.'
              : 'No matching menu items.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
      );
    }

    final names = {
      for (final category in categories) category.id: category.name,
    };
    return ListView.separated(
      key: const ValueKey('admin-menu-list'),
      itemCount: visible.length,
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = visible[index];
        return AdminMenuItemCard(
          key: ValueKey(item.id),
          item: item,
          categoryName: names[item.categoryId] ?? 'Unknown category',
          actionsEnabled: actionsEnabled,
          onAvailabilityChanged: (value) => onAvailabilityChanged(item, value),
          onPublishedChanged: (value) => onPublishedChanged(item, value),
          onEdit: () => onEdit(item),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Menu items could not be loaded.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
