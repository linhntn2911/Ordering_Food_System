import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_providers.dart';
import '../../data/repositories/firestore_category_repository.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return FirestoreCategoryRepository(ref.watch(firebaseFirestoreProvider));
});

final categoriesProvider = StreamProvider.autoDispose<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchCategories();
});

final categoryManagementViewModelProvider =
    AsyncNotifierProvider<CategoryManagementViewModel, void>(
      CategoryManagementViewModel.new,
    );

class CategoryManagementViewModel extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> save({
    String? id,
    required String name,
    required String imageUrl,
    required bool isPublished,
  }) async {
    final normalizedName = name.trim();
    final normalizedImageUrl = imageUrl.trim();
    final validationError = validate(
      name: normalizedName,
      imageUrl: normalizedImageUrl,
    );
    if (validationError != null) {
      state = AsyncError(ArgumentError(validationError), StackTrace.current);
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(categoryRepositoryProvider);
      if (id == null) {
        await repository.createCategory(
          name: normalizedName,
          imageUrl: normalizedImageUrl,
          isPublished: isPublished,
        );
      } else {
        await repository.updateCategory(
          id: id,
          name: normalizedName,
          imageUrl: normalizedImageUrl,
          isPublished: isPublished,
        );
      }
    });
    return !state.hasError;
  }

  Future<void> setPublished(Category category, bool value) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(categoryRepositoryProvider)
          .setPublished(category.id, isPublished: value),
    );
  }

  Future<void> move(Category category, Category adjacent) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(categoryRepositoryProvider)
          .swapSortOrder(category, adjacent),
    );
  }

  static String? validate({required String name, required String imageUrl}) {
    if (name.length < 2) return 'Tên phải có ít nhất 2 ký tự.';
    if (name.length > 50) return 'Tên không được vượt quá 50 ký tự.';
    if (imageUrl.isNotEmpty) {
      final uri = Uri.tryParse(imageUrl);
      if (uri == null ||
          !uri.hasAbsolutePath ||
          (uri.scheme != 'http' && uri.scheme != 'https')) {
        return 'Đường dẫn ảnh phải bắt đầu bằng http:// hoặc https://.';
      }
    }
    return null;
  }
}
