import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/admin_drawer.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../domain/entities/category.dart';
import '../viewmodels/category_management_view_model.dart';
import '../widgets/category_card.dart';
import '../widgets/category_form_sheet.dart';
import '../../../menu/presentation/views/admin_menu_item_list_screen.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  String _query = '';

  Future<void> _openForm([Category? category]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.dialog),
        ),
      ),
      builder: (_) => CategoryFormSheet(category: category),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryStart,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                category == null
                    ? 'Category created successfully.'
                    : 'Category updated successfully.',
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final action = ref.watch(categoryManagementViewModelProvider);

    ref.listen(categoryManagementViewModelProvider, (previous, next) {
      if (next.hasError && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(next.error)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      drawer: const AdminDrawer(
        currentDestination: AdminDestination.categories,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360
                ? AppSpacing.md
                : AppSpacing.xl;
            final compact = constraints.maxWidth < 360;
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
                        onRefresh: () => ref.invalidate(categoriesProvider),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Category Management',
                        style: AppTextStyles.headlineLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Keep your food menu clear, organized, and easy to explore.',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      categories.maybeWhen(
                        data: (items) => compact
                            ? _CompactSummary(items: items)
                            : _CategorySummary(items: items),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SearchField(
                        onChanged: (value) =>
                            setState(() => _query = value.trim()),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: categories.when(
                            loading: () => const _LoadingState(),
                            error: (error, _) => _ErrorState(
                              message: _friendlyError(error),
                              onRetry: () => ref.invalidate(categoriesProvider),
                            ),
                            data: (items) => _CategoryList(
                              items: items,
                              query: _query,
                              actionsEnabled: !action.isLoading,
                              onAdd: _openForm,
                              onEdit: _openForm,
                              onRefresh: () async {
                                ref.invalidate(categoriesProvider);
                                await ref.read(categoriesProvider.future);
                              },
                              onPublishedChanged: (category, value) => ref
                                  .read(
                                    categoryManagementViewModelProvider
                                        .notifier,
                                  )
                                  .setPublished(category, value),
                              onMove: (category, adjacent) => ref
                                  .read(
                                    categoryManagementViewModelProvider
                                        .notifier,
                                  )
                                  .move(category, adjacent),
                            ),
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
      bottomNavigationBar: _BottomAction(
        enabled: !action.isLoading,
        onPressed: _openForm,
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Builder(
          builder: (scaffoldContext) => IconButton(
            key: const ValueKey('admin-drawer-button'),
            tooltip: 'Open navigation menu',
            onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.primaryEnd,
              backgroundColor: AppColors.primarySoft,
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
              Text('Admin workspace', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh categories',
          onPressed: onRefresh,
          style: IconButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
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

class _CategorySummary extends StatelessWidget {
  const _CategorySummary({required this.items});

  final List<Category> items;

  @override
  Widget build(BuildContext context) {
    final published = items.where((item) => item.isPublished).length;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(value: '${items.length}', label: 'Categories'),
          ),
          const SizedBox(height: 36, child: VerticalDivider()),
          Expanded(
            child: _Metric(value: '$published', label: 'Published'),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: AppColors.primaryEnd,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactSummary extends StatelessWidget {
  const _CompactSummary({required this.items});

  final List<Category> items;

  @override
  Widget build(BuildContext context) {
    final published = items.where((item) => item.isPublished).length;
    return Row(
      children: [
        const Icon(
          Icons.auto_awesome_rounded,
          size: 18,
          color: AppColors.primaryEnd,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            '${items.length} categories · $published published',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primaryEnd,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.titleLarge),
          Text(label, style: AppTextStyles.labelSmall),
        ],
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
          hintText: 'Search categories',
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primaryEnd),
          suffixIcon: Icon(Icons.tune_rounded, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.items,
    required this.query,
    required this.actionsEnabled,
    required this.onAdd,
    required this.onEdit,
    required this.onRefresh,
    required this.onPublishedChanged,
    required this.onMove,
  });

  final List<Category> items;
  final String query;
  final bool actionsEnabled;
  final VoidCallback onAdd;
  final ValueChanged<Category> onEdit;
  final Future<void> Function() onRefresh;
  final void Function(Category, bool) onPublishedChanged;
  final void Function(Category, Category) onMove;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _EmptyState(onAdd: onAdd);

    final normalizedQuery = query.toLowerCase();
    final visible = normalizedQuery.isEmpty
        ? items
        : items
              .where(
                (item) => item.name.toLowerCase().contains(normalizedQuery),
              )
              .toList(growable: false);
    if (visible.isEmpty) return const _NoSearchResults();

    return RefreshIndicator(
      color: AppColors.primaryEnd,
      onRefresh: onRefresh,
      child: ListView.separated(
        key: const ValueKey('category-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        itemCount: visible.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = visible[index];
          final originalIndex = items.indexWhere(
            (item) => item.id == category.id,
          );
          return CategoryCard(
            key: ValueKey(category.id),
            category: category,
            position: originalIndex + 1,
            canMoveUp: originalIndex > 0 && normalizedQuery.isEmpty,
            canMoveDown:
                originalIndex < items.length - 1 && normalizedQuery.isEmpty,
            actionsEnabled: actionsEnabled,
            onEdit: () => onEdit(category),
            onViewItems: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    AdminMenuItemListScreen(initialCategoryId: category.id),
              ),
            ),
            onPublishedChanged: (value) => onPublishedChanged(category, value),
            onMoveUp: () => onMove(category, items[originalIndex - 1]),
            onMoveDown: () => onMove(category, items[originalIndex + 1]),
          );
        },
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [AppShadows.card],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: GradientButton(
                label: 'Add new category',
                icon: Icons.add_rounded,
                onPressed: enabled ? onPressed : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _friendlyError(Object? error) {
  final value = error.toString().toLowerCase();
  if (value.contains('permission-denied')) {
    return 'Admin sign-in is required to manage categories.';
  }
  if (value.contains('network')) {
    return 'Check your internet connection and try again.';
  }
  if (error is ArgumentError) {
    return error.message?.toString() ?? 'Please check the entered information.';
  }
  return 'Categories could not be loaded. Please try again.';
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const ValueKey('category-loading'),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => Container(
        height: 164,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('category-empty'),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.category_rounded,
                size: 40,
                color: AppColors.primaryEnd,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No categories yet', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Create the first category before adding menu items.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create category'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('category-error'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.errorSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              size: 36,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
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

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('category-no-results'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No categories match your search.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
