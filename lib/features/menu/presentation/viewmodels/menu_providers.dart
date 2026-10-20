import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_providers.dart';
import '../../data/repositories/firestore_menu_repository.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/repositories/menu_repository.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return FirestoreMenuRepository(ref.watch(firebaseFirestoreProvider));
});

final publishedMenuProvider = StreamProvider.autoDispose
    .family<List<MenuItem>, String?>((ref, categoryId) {
      return ref
          .watch(menuRepositoryProvider)
          .watchPublishedItems(categoryId: categoryId);
    });
