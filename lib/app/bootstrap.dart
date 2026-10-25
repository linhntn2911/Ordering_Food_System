import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/category/data/repositories/preview_category_repository.dart';
import '../features/category/presentation/viewmodels/category_management_view_model.dart';
import '../features/menu/data/repositories/preview_menu_repository.dart';
import '../features/menu/presentation/viewmodels/menu_providers.dart';
import '../features/order/data/repositories/preview_order_repository.dart';
import '../features/order/presentation/viewmodels/admin_order_list_view_model.dart';
import '../firebase_options.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode && FirebaseAuth.instance.currentUser == null) {
      _runPreview();
      return;
    }
    runApp(const ProviderScope(child: FoodOrderingApp()));
  } on UnsupportedError {
    if (!kIsWeb || !kDebugMode) {
      rethrow;
    }
    _runPreview();
  }
}

void _runPreview() {
  runApp(
    ProviderScope(
      overrides: [
        categoryRepositoryProvider.overrideWith((ref) {
          final repository = PreviewCategoryRepository();
          ref.onDispose(repository.dispose);
          return repository;
        }),
        menuRepositoryProvider.overrideWith((ref) {
          final repository = PreviewMenuRepository();
          ref.onDispose(repository.dispose);
          return repository;
        }),
        orderRepositoryProvider.overrideWith((ref) {
          final repository = PreviewOrderRepository();
          ref.onDispose(repository.dispose);
          return repository;
        }),
      ],
      child: const FoodOrderingApp(showPreviewBanner: true),
    ),
  );
}
