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
    if (name.isEmpty) return 'Vui lòng nhập tên món.';
    if (name.length < 2) return 'Tên món phải có ít nhất 2 ký tự.';
    if (name.length > 80) return 'Tên món không được vượt quá 80 ký tự.';
    return null;
  }

  static String? validateDescription(String? value) {
    if ((value?.trim().length ?? 0) > 300) {
      return 'Mô tả không được vượt quá 300 ký tự.';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    final normalized = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final price = int.tryParse(normalized);
    if (price == null || price <= 0) return 'Vui lòng nhập giá lớn hơn 0.';
    if (price > 10000000) return 'Giá không được vượt quá 10.000.000 ₫.';
    return null;
  }

  static String? validateSurcharge(String? value) {
    final normalized = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final price = int.tryParse(normalized);
    if (price == null) return 'Vui lòng nhập phụ thu cỡ L.';
    if (price < 0 || price > 1000000) {
      return 'Phụ thu phải từ 0 đến 1.000.000 ₫.';
    }
    return null;
  }

  static String? validateDraft(MenuItemDraft draft) {
    final nameError = validateName(draft.name);
    if (nameError != null) return nameError;
    if (draft.categoryId.trim().isEmpty) return 'Vui lòng chọn danh mục.';
    if (draft.basePrice <= 0) return 'Vui lòng nhập giá lớn hơn 0.';
    if (draft.description.length > 300) {
      return 'Mô tả không được vượt quá 300 ký tự.';
    }
    if (draft.existingImageUrl.isEmpty && draft.imageBytes == null) {
      return 'Vui lòng chọn ảnh món ăn.';
    }
    if (draft.sizes.any((size) => size.priceDelta < 0)) {
      return 'Phụ thu kích cỡ không được là số âm.';
    }
    return null;
  }
}
