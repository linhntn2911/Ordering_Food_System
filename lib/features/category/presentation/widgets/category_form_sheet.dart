import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../domain/entities/category.dart';
import '../viewmodels/category_management_view_model.dart';

class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({this.category, super.key});

  final Category? category;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _imageController;
  late bool _isPublished;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _imageController = TextEditingController(text: widget.category?.imageUrl);
    _isPublished = widget.category?.isPublished ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final saved = await ref
        .read(categoryManagementViewModelProvider.notifier)
        .save(
          id: widget.category?.id,
          name: _nameController.text,
          imageUrl: _imageController.text,
          isPublished: _isPublished,
        );
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(categoryManagementViewModelProvider);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.md,
            bottom: keyboardInset + AppSpacing.xl,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(AppRadii.small),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppGradients.primary,
                            borderRadius: BorderRadius.circular(
                              AppRadii.medium,
                            ),
                          ),
                          child: Icon(
                            widget.category == null
                                ? Icons.add_rounded
                                : Icons.edit_rounded,
                            color: AppColors.surface,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.category == null
                                    ? 'Add category'
                                    : 'Edit category',
                                style: AppTextStyles.headlineMedium,
                              ),
                              Text(
                                'Complete the information below.',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: action.isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      maxLength: 50,
                      decoration: const InputDecoration(
                        labelText: 'Category name',
                        hintText: 'For example: Main dishes',
                        prefixIcon: Icon(Icons.restaurant_menu_rounded),
                      ),
                      validator: (value) => (value?.trim().length ?? 0) < 2
                          ? 'Enter at least 2 characters.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _imageController,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Image URL (optional)',
                        hintText: 'https://example.com/category.jpg',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                      validator: (value) {
                        final error = CategoryManagementViewModel.validate(
                          name: _nameController.text.trim(),
                          imageUrl: value?.trim() ?? '',
                        );
                        return error?.startsWith('Image') == true
                            ? error
                            : null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Material(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        child: SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(
                            Icons.visibility_rounded,
                            color: AppColors.primaryEnd,
                          ),
                          title: Text(
                            'Published',
                            style: AppTextStyles.titleMedium,
                          ),
                          subtitle: Text(
                            'Customers can see this category.',
                            style: AppTextStyles.bodySmall,
                          ),
                          value: _isPublished,
                          onChanged: action.isLoading
                              ? null
                              : (value) => setState(() => _isPublished = value),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    GradientButton(
                      label: widget.category == null
                          ? 'Create category'
                          : 'Save changes',
                      isLoading: action.isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
