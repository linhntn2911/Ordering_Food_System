import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/menu_item_draft.dart';
import 'menu_providers.dart';

final menuItemFormViewModelProvider =
    AsyncNotifierProvider.autoDispose<MenuItemFormViewModel, String?>(
      MenuItemFormViewModel.new,
    );

class MenuItemFormViewModel extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() => null;

  Future<bool> save(MenuItemDraft draft) async {
    final validationError = validateDraft(draft);
    if (validationError != null) {
      state = AsyncError(ArgumentError(validationError), StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(menuRepositoryProvider).saveItem(draft),
    );
    return !state.hasError;
  }

  static String? validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter the item name.';
    if (name.length < 2) return 'Name must contain at least 2 characters.';
    if (name.length > 80) return 'Name cannot exceed 80 characters.';
    return null;
  }

  static String? validateDescription(String? value) {
    if ((value?.trim().length ?? 0) > 300) {
      return 'Description cannot exceed 300 characters.';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    final normalized = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final price = int.tryParse(normalized);
    if (price == null || price <= 0) return 'Enter a price greater than 0.';
    if (price > 10000000) return 'Price cannot exceed 10,000,000 VND.';
    return null;
  }

  static String? validateSurcharge(String? value) {
    final normalized = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final price = int.tryParse(normalized);
    if (price == null) return 'Enter the L-size surcharge.';
    if (price < 0 || price > 1000000) {
      return 'Surcharge must be from 0 to 1,000,000 VND.';
    }
    return null;
  }

  static String? validateDraft(MenuItemDraft draft) {
    final nameError = validateName(draft.name);
    if (nameError != null) return nameError;
    if (draft.categoryId.trim().isEmpty) return 'Select a category.';
    if (draft.basePrice <= 0) return 'Enter a price greater than 0.';
    if (draft.description.length > 300) {
      return 'Description cannot exceed 300 characters.';
    }
    if (draft.existingImageUrl.isEmpty && draft.imageBytes == null) {
      return 'Select an item image.';
    }
    if (draft.sizes.any((size) => size.additionalPrice < 0)) {
      return 'Size surcharge cannot be negative.';
    }
    return null;
  }
}
