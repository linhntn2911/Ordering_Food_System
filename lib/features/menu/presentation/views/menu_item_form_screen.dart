import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/viewmodels/category_management_view_model.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_item_draft.dart';
import '../../domain/entities/menu_option.dart';
import '../../domain/repositories/menu_repository.dart';
import '../viewmodels/menu_item_form_view_model.dart';

class MenuItemFormScreen extends ConsumerStatefulWidget {
  const MenuItemFormScreen({this.item, this.initialCategoryId, super.key});

  final MenuItem? item;
  final String? initialCategoryId;

  bool get isEditing => item != null;

  @override
  ConsumerState<MenuItemFormScreen> createState() => _MenuItemFormScreenState();
}

class _MenuItemFormScreenState extends ConsumerState<MenuItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _largeSurchargeController;
  late final TextEditingController _imageUrlController;
  String? _categoryId;
  bool _isAvailable = true;
  bool _isPublished = true;
  bool _hasSizes = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _priceController = TextEditingController(
      text: item == null ? '' : item.basePrice.toString(),
    );
    final largeSize = item?.sizes.where((size) => size.name == 'L').firstOrNull;
    _largeSurchargeController = TextEditingController(
      text: largeSize?.priceDelta.toString() ?? '',
    );
    _imageUrlController = TextEditingController(text: item?.imageUrl ?? '');
    _categoryId = item?.categoryId ?? widget.initialCategoryId;
    _isAvailable = item?.isAvailable ?? true;
    _isPublished = item?.isPublished ?? true;
    _hasSizes = item?.sizes.isNotEmpty ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _largeSurchargeController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final saveState = ref.watch(menuItemFormViewModelProvider);

    ref.listen(menuItemFormViewModelProvider, (previous, next) {
      if (next.hasError && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_messageFor(next.error)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360
                ? AppSpacing.md
                : AppSpacing.xl;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Form(
                  key: _formKey,
                  child: CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          AppSpacing.md,
                          horizontalPadding,
                          AppSpacing.xl,
                        ),
                        sliver: SliverList.list(
                          children: [
                            _FormTopBar(
                              isEditing: widget.isEditing,
                              onBack: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              widget.isEditing
                                  ? 'Chỉnh sửa món ăn'
                                  : 'Thêm món ăn',
                              style: AppTextStyles.headlineLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Giữ thực đơn Ngô Chicken rõ ràng và luôn được cập nhật.',
                              style: AppTextStyles.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _ImagePickerCard(
                              imageUrl: _imageUrlController.text.trim(),
                              imageUrlController: _imageUrlController,
                              isBusy: saveState.isLoading,
                              onUrlChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _SectionTitle(
                              icon: Icons.restaurant_menu_rounded,
                              label: 'Thông tin món ăn',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              key: const ValueKey('menu-item-name'),
                              controller: _nameController,
                              enabled: !saveState.isLoading,
                              textInputAction: TextInputAction.next,
                              validator: MenuItemFormViewModel.validateName,
                              decoration: const InputDecoration(
                                labelText: 'Tên món *',
                                hintText: 'Ví dụ: Gà sốt phô mai cay',
                                prefixIcon: Icon(Icons.fastfood_rounded),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            categories.when(
                              loading: () => const LinearProgressIndicator(
                                color: AppColors.primaryEnd,
                              ),
                              error: (_, _) => _CategoryLoadError(
                                onRetry: () =>
                                    ref.invalidate(categoriesProvider),
                              ),
                              data: (data) => _CategoryDropdown(
                                categories: data,
                                value: _validCategoryId(data),
                                enabled: !saveState.isLoading,
                                onChanged: (value) =>
                                    setState(() => _categoryId = value),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              key: const ValueKey('menu-item-description'),
                              controller: _descriptionController,
                              enabled: !saveState.isLoading,
                              minLines: 3,
                              maxLines: 5,
                              maxLength: 300,
                              validator:
                                  MenuItemFormViewModel.validateDescription,
                              decoration: const InputDecoration(
                                labelText: 'Mô tả',
                                hintText:
                                    'Nguyên liệu, hương vị hoặc cách dùng món',
                                alignLabelWithHint: true,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              key: const ValueKey('menu-item-price'),
                              controller: _priceController,
                              enabled: !saveState.isLoading,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              validator: MenuItemFormViewModel.validatePrice,
                              decoration: const InputDecoration(
                                labelText: 'Giá cơ bản *',
                                hintText: '35000',
                                prefixIcon: Icon(Icons.payments_outlined),
                                suffixText: 'VND',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _SectionTitle(
                              icon: Icons.tune_rounded,
                              label: 'Kích cỡ',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _SettingCard(
                              title: 'Có kích cỡ M và L',
                              subtitle: 'M dùng giá cơ bản; nhập phần giá tăng thêm cho L.',
                              value: _hasSizes,
                              enabled: !saveState.isLoading,
                              onChanged: (value) =>
                                  setState(() => _hasSizes = value),
                            ),
                            if (_hasSizes) ...[
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                key: const ValueKey('large-size-surcharge'),
                                controller: _largeSurchargeController,
                                enabled: !saveState.isLoading,
                                keyboardType: TextInputType.number,
                                validator:
                                    MenuItemFormViewModel.validateSurcharge,
                                decoration: const InputDecoration(
                                  labelText: 'Phụ thu cỡ L *',
                                  hintText: '5000',
                                  prefixIcon: Icon(Icons.add_circle_outline),
                                  suffixText: 'VND',
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            _SectionTitle(
                              icon: Icons.visibility_rounded,
                              label: 'Trạng thái bán',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _SettingCard(
                              title: _isAvailable ? 'Còn hàng' : 'Hết hàng',
                              subtitle:
                                  'Khách có thể đặt món này khi còn hàng.',
                              value: _isAvailable,
                              enabled: !saveState.isLoading,
                              onChanged: (value) =>
                                  setState(() => _isAvailable = value),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _SettingCard(
                              title: _isPublished ? 'Đã đăng' : 'Đã ẩn',
                              subtitle: 'Món đã đăng có thể xuất hiện trong thực đơn khách hàng.',
                              value: _isPublished,
                              enabled: !saveState.isLoading,
                              onChanged: (value) =>
                                  setState(() => _isPublished = value),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            GradientButton(
                              label: widget.isEditing
                                  ? 'Lưu thay đổi'
                                  : 'Thêm món ăn',
                              icon: Icons.check_rounded,
                              isLoading: saveState.isLoading,
                              onPressed: categories.hasValue ? _submit : null,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
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

  String? _validCategoryId(List<Category> categories) {
    if (categories.any((category) => category.id == _categoryId)) {
      return _categoryId;
    }
    return null;
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn danh mục.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_imageUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ảnh món ăn.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!valid) return;

    final sizes = _hasSizes
        ? [
            const MenuOption(id: 'm', name: 'M', priceDelta: 0),
            MenuOption(
              id: 'l',
              name: 'L',
              priceDelta: _parseMoney(_largeSurchargeController.text),
            ),
          ]
        : const <MenuOption>[];
    final draft = MenuItemDraft(
      id: widget.item?.id,
      categoryId: _categoryId!,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      existingImageUrl: _imageUrlController.text.trim(),
      imageBytes: null,
      imageName: null,
      basePrice: _parseMoney(_priceController.text),
      isAvailable: _isAvailable,
      isPublished: _isPublished,
      sortOrder: widget.item?.sortOrder ?? 0,
      sizes: sizes,
    );
    final saved = await ref
        .read(menuItemFormViewModelProvider.notifier)
        .save(draft);
    if (!mounted || !saved) return;
    Navigator.of(context).pop(true);
  }

  int _parseMoney(String value) =>
      int.parse(value.replaceAll(RegExp(r'[^0-9]'), ''));

  String _messageFor(Object? error) {
    if (error is ArgumentError) return error.message.toString();
    if (error is MenuImageUploadException) return error.message;
    return 'Không thể lưu món ăn. Vui lòng thử lại.';
  }
}

class _FormTopBar extends StatelessWidget {
  const _FormTopBar({required this.isEditing, required this.onBack});

  final bool isEditing;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Quay lại món ăn',
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primarySoft,
            foregroundColor: AppColors.primaryEnd,
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ngô Chicken', style: AppTextStyles.titleMedium),
              Text(
                isEditing ? 'Cập nhật món ăn hiện có' : 'Tạo món ăn mới',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.imageUrl,
    required this.imageUrlController,
    required this.isBusy,
    required this.onUrlChanged,
  });

  final String imageUrl;
  final TextEditingController imageUrlController;
  final bool isBusy;
  final ValueChanged<String> onUrlChanged;

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (imageUrl.isNotEmpty) {
      image = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _ImagePlaceholder(),
      );
    } else {
      image = const _ImagePlaceholder();
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.medium),
            child: AspectRatio(aspectRatio: 16 / 9, child: image),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Chế độ miễn phí: dán đường dẫn ảnh công khai. Tải ảnh lên Firebase Storage yêu cầu gói Blaze.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: imageUrlController,
            enabled: !isBusy,
            keyboardType: TextInputType.url,
            onChanged: onUrlChanged,
            decoration: const InputDecoration(
              labelText: 'URL ảnh (miễn phí)',
              hintText: 'https://.../food.jpg',
              prefixIcon: Icon(Icons.link_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.warningSurface,
      child: Center(
        child: Icon(Icons.fastfood_rounded, size: 54, color: AppColors.warning),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryEnd, size: 21),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTextStyles.titleMedium),
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final List<Category> categories;
  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: const ValueKey('menu-item-category'),
      initialValue: value,
      items: categories
          .map(
            (category) => DropdownMenuItem(
              value: category.id,
              child: Text(category.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: enabled ? onChanged : null,
      validator: (selected) =>
          selected == null ? 'Vui lòng chọn danh mục.' : null,
      decoration: const InputDecoration(
        labelText: 'Danh mục *',
        prefixIcon: Icon(Icons.category_outlined),
      ),
    );
  }
}

class _CategoryLoadError extends StatelessWidget {
  const _CategoryLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: AppSpacing.xs),
          const Expanded(child: Text('Không thể tải danh mục.')),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: value ? AppColors.primaryTint : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: AppColors.primaryEnd,
          ),
        ],
      ),
    );
  }
}
