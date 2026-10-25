import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/viewmodels/category_management_view_model.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_item_draft.dart';
import '../../domain/entities/menu_size_option.dart';
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
  String? _categoryId;
  bool _isAvailable = true;
  bool _isPublished = true;
  bool _hasSizes = false;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isPickingImage = false;

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
      text: largeSize?.additionalPrice.toString() ?? '',
    );
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
                                  ? 'Edit Menu Item'
                                  : 'Add Menu Item',
                              style: AppTextStyles.headlineLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Keep the Ngô Chicken menu clear and up to date.',
                              style: AppTextStyles.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _ImagePickerCard(
                              bytes: _imageBytes,
                              imageUrl: widget.item?.imageUrl ?? '',
                              isBusy: _isPickingImage || saveState.isLoading,
                              onPick: _pickImage,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _SectionTitle(
                              icon: Icons.restaurant_menu_rounded,
                              label: 'Item information',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              key: const ValueKey('menu-item-name'),
                              controller: _nameController,
                              enabled: !saveState.isLoading,
                              textInputAction: TextInputAction.next,
                              validator: MenuItemFormViewModel.validateName,
                              decoration: const InputDecoration(
                                labelText: 'Item name *',
                                hintText: 'Example: Gà sốt phô mai cay',
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
                                labelText: 'Description',
                                hintText:
                                    'Ingredients, flavour, or serving notes',
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
                                labelText: 'Base price *',
                                hintText: '35000',
                                prefixIcon: Icon(Icons.payments_outlined),
                                suffixText: 'VND',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _SectionTitle(
                              icon: Icons.tune_rounded,
                              label: 'Sizes',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _SettingCard(
                              title: 'Offer M and L sizes',
                              subtitle: 'M uses the base price; set the extra amount for L.',
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
                                  labelText: 'L-size surcharge *',
                                  hintText: '5000',
                                  prefixIcon: Icon(Icons.add_circle_outline),
                                  suffixText: 'VND',
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            _SectionTitle(
                              icon: Icons.visibility_rounded,
                              label: 'Selling status',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _SettingCard(
                              title: _isAvailable ? 'Available' : 'Sold out',
                              subtitle: 'Customers can order this item while available.',
                              value: _isAvailable,
                              enabled: !saveState.isLoading,
                              onChanged: (value) =>
                                  setState(() => _isAvailable = value),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _SettingCard(
                              title: _isPublished ? 'Published' : 'Hidden',
                              subtitle: 'Published items can appear in the customer menu.',
                              value: _isPublished,
                              enabled: !saveState.isLoading,
                              onChanged: (value) =>
                                  setState(() => _isPublished = value),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            GradientButton(
                              label: widget.isEditing
                                  ? 'Save changes'
                                  : 'Add menu item',
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

  Future<void> _pickImage() async {
    setState(() => _isPickingImage = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Choose an image smaller than 5 MB.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The image could not be selected.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a category.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_imageBytes == null && (widget.item?.imageUrl.isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select an item image.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!valid) return;

    final sizes = _hasSizes
        ? [
            const MenuSizeOption(name: 'M', additionalPrice: 0),
            MenuSizeOption(
              name: 'L',
              additionalPrice: _parseMoney(_largeSurchargeController.text),
            ),
          ]
        : const <MenuSizeOption>[];
    final draft = MenuItemDraft(
      id: widget.item?.id,
      categoryId: _categoryId!,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      existingImageUrl: widget.item?.imageUrl ?? '',
      imageBytes: _imageBytes,
      imageName: _imageName,
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
    return 'The menu item could not be saved. Please try again.';
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
          tooltip: 'Back to menu items',
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
                isEditing ? 'Update an existing item' : 'Create a new item',
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
    required this.bytes,
    required this.imageUrl,
    required this.isBusy,
    required this.onPick,
  });

  final Uint8List? bytes;
  final String imageUrl;
  final bool isBusy;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (bytes != null) {
      image = Image.memory(bytes!, fit: BoxFit.cover);
    } else if (imageUrl.isNotEmpty) {
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
          OutlinedButton.icon(
            key: const ValueKey('pick-menu-item-image'),
            onPressed: isBusy ? null : onPick,
            icon: isBusy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate_outlined),
            label: Text(
              imageUrl.isEmpty && bytes == null
                  ? 'Choose image *'
                  : 'Replace image',
            ),
          ),
          Text(
            'JPG or PNG, up to 5 MB',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
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
      validator: (selected) => selected == null ? 'Select a category.' : null,
      decoration: const InputDecoration(
        labelText: 'Category *',
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
          const Expanded(child: Text('Categories could not be loaded.')),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
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
