import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import 'models/address_model.dart';

/// Abstract repository for delivery address operations (FR-017, FR-018, BR-008)
abstract class AddressRepository {
  /// Synchronously retrieve cached addresses for a user
  List<AddressModel> getCachedAddresses(String userId);

  /// Fetch all delivery addresses owned by the specified customer
  Future<List<AddressModel>> getAddresses(String userId);

  /// Retrieve current default address for the customer
  Future<AddressModel?> getDefaultAddress(String userId);

  /// Add a new address (FR-017)
  Future<void> addAddress(String userId, AddressModel address);

  /// Update an existing address (FR-017)
  Future<void> updateAddress(String userId, AddressModel address);

  /// Delete an address (FR-017)
  Future<void> deleteAddress(String userId, String addressId);

  /// Mark an address as default and atomically clear default flag on all others (FR-018, User Story 8 Scenario 2)
  Future<void> setDefaultAddress(String userId, String addressId);

  /// Stream real-time changes to the customer's addresses
  Stream<List<AddressModel>> watchAddresses(String userId);
}

/// Implementation of AddressRepository with user-isolated data store (BR-008)
class AddressRepositoryImpl implements AddressRepository {
  static final List<AddressModel> _demoAddresses = [
    AddressModel(
      id: 'mock_addr_home',
      userId: 'customer_demo_uid',
      label: 'Nhà riêng',
      recipientName: 'Hồng Anh',
      phoneNumber: '0901234567',
      streetAddress: '123 Lê Lợi',
      ward: 'Bến Nghé',
      district: 'Quận 1',
      city: 'TP. Hồ Chí Minh',
      latitude: 10.7720,
      longitude: 106.6980, // ~0.6 km from restaurant
      isDefault: true, // FR-018: Exactly one default
      createdAt: DateTime.now(),
    ),
    AddressModel(
      id: 'mock_addr_office',
      userId: 'customer_demo_uid',
      label: 'Văn phòng',
      recipientName: 'Hồng Anh',
      phoneNumber: '0987654321',
      streetAddress: 'Tòa nhà Bitexco, 2 Hải Triều',
      ward: 'Bến Nghé',
      district: 'Quận 1',
      city: 'TP. Hồ Chí Minh',
      latitude: 10.7715,
      longitude: 106.7040, // ~0.7 km from restaurant
      isDefault: false,
      createdAt: DateTime.now(),
    ),
  ];

  // Backing store isolated by customer UID (BR-008)
  final Map<String, List<AddressModel>> _userAddresses = {
    'customer_demo_uid': List.from(_demoAddresses),
  };
  final Map<String, StreamController<List<AddressModel>>> _controllers = {};

  StreamController<List<AddressModel>> _getController(String userId) {
    return _controllers.putIfAbsent(
      userId,
      () => StreamController<List<AddressModel>>.broadcast(),
    );
  }

  void _notify(String userId) {
    final list = _userAddresses[userId] ?? [];
    _getController(userId).add(List.unmodifiable(list));
  }

  @override
  List<AddressModel> getCachedAddresses(String userId) {
    if (userId.trim().isEmpty) return const [];
    return List.unmodifiable(_userAddresses[userId] ?? []);
  }

  @override
  Future<List<AddressModel>> getAddresses(String userId) async {
    if (userId.trim().isEmpty) {
      throw const AuthFailure('Bạn cần đăng nhập để xem danh sách địa chỉ.');
    }
    try {
      final list = _userAddresses[userId] ?? [];
      return List.unmodifiable(list);
    } catch (e) {
      throw AddressFailure('Lỗi khi tải danh sách địa chỉ: ${e.toString()}');
    }
  }

  @override
  Future<AddressModel?> getDefaultAddress(String userId) async {
    if (userId.trim().isEmpty) return null;
    final list = _userAddresses[userId] ?? [];
    try {
      return list.cast<AddressModel?>().firstWhere(
        (element) => element?.isDefault == true,
        orElse: () => list.isNotEmpty ? list.first : null,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addAddress(String userId, AddressModel address) async {
    if (userId.trim().isEmpty) {
      throw const AuthFailure('Bạn cần đăng nhập để thêm địa chỉ.');
    }

    final validationErrors = address.getValidationErrors();
    if (validationErrors.isNotEmpty) {
      throw ValidationFailure(validationErrors.first);
    }

    try {
      final list = List<AddressModel>.from(_userAddresses[userId] ?? []);

      // If this is the user's first address, or is marked default, enforce single default rule
      final bool shouldBeDefault = address.isDefault || list.isEmpty;

      final updatedList = <AddressModel>[];
      for (final existing in list) {
        if (shouldBeDefault) {
          // Unset default on all existing addresses (User Story 8, Scenario 2)
          updatedList.add(existing.copyWith(isDefault: false));
        } else {
          updatedList.add(existing);
        }
      }

      final newAddress = address.copyWith(
        id: address.id.isNotEmpty
            ? address.id
            : 'addr_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        isDefault: shouldBeDefault,
      );

      updatedList.add(newAddress);
      _userAddresses[userId] = updatedList;
      _notify(userId);
    } catch (e) {
      if (e is Failure) rethrow;
      throw AddressFailure('Lỗi khi lưu địa chỉ: ${e.toString()}');
    }
  }

  @override
  Future<void> updateAddress(String userId, AddressModel address) async {
    if (userId.trim().isEmpty) {
      throw const AuthFailure('Bạn cần đăng nhập để cập nhật địa chỉ.');
    }

    final validationErrors = address.getValidationErrors();
    if (validationErrors.isNotEmpty) {
      throw ValidationFailure(validationErrors.first);
    }

    try {
      final list = List<AddressModel>.from(_userAddresses[userId] ?? []);
      final index = list.indexWhere((e) => e.id == address.id);
      if (index == -1) {
        throw const AddressFailure('Không tìm thấy địa chỉ cần cập nhật.');
      }

      final updatedList = <AddressModel>[];
      for (final item in list) {
        if (item.id == address.id) {
          updatedList.add(
            address.copyWith(userId: userId, updatedAt: DateTime.now()),
          );
        } else {
          if (address.isDefault) {
            // Unset default on all other addresses (User Story 8, Scenario 2)
            updatedList.add(item.copyWith(isDefault: false));
          } else {
            updatedList.add(item);
          }
        }
      }

      // If user unselected default on the only default item, retain at least one default if list not empty
      final hasDefault = updatedList.any((e) => e.isDefault);
      if (!hasDefault && updatedList.isNotEmpty) {
        updatedList[0] = updatedList[0].copyWith(isDefault: true);
      }

      _userAddresses[userId] = updatedList;
      _notify(userId);
    } catch (e) {
      if (e is Failure) rethrow;
      throw AddressFailure('Lỗi khi cập nhật địa chỉ: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAddress(String userId, String addressId) async {
    if (userId.trim().isEmpty) {
      throw const AuthFailure('Bạn cần đăng nhập để xóa địa chỉ.');
    }

    try {
      final list = List<AddressModel>.from(_userAddresses[userId] ?? []);
      final targetIndex = list.indexWhere((e) => e.id == addressId);
      if (targetIndex == -1) return;

      final bool wasDefault = list[targetIndex].isDefault;
      list.removeAt(targetIndex);

      // If deleted address was default, promote the first remaining address to default
      if (wasDefault && list.isNotEmpty) {
        list[0] = list[0].copyWith(isDefault: true);
      }

      _userAddresses[userId] = list;
      _notify(userId);
    } catch (e) {
      if (e is Failure) rethrow;
      throw AddressFailure('Lỗi khi xóa địa chỉ: ${e.toString()}');
    }
  }

  @override
  Future<void> setDefaultAddress(String userId, String addressId) async {
    if (userId.trim().isEmpty) {
      throw const AuthFailure(
        'Bạn cần đăng nhập để thiết lập địa chỉ mặc định.',
      );
    }

    try {
      final list = List<AddressModel>.from(_userAddresses[userId] ?? []);
      final targetExists = list.any((e) => e.id == addressId);
      if (!targetExists) {
        throw const AddressFailure('Không tìm thấy địa chỉ được chọn.');
      }

      // User Story 8 Scenario 2: Exactly one default address per customer
      final updatedList = list.map((item) {
        if (item.id == addressId) {
          return item.copyWith(isDefault: true);
        } else {
          return item.copyWith(isDefault: false);
        }
      }).toList();

      _userAddresses[userId] = updatedList;
      _notify(userId);
    } catch (e) {
      if (e is Failure) rethrow;
      throw AddressFailure(
        'Lỗi khi thiết lập địa chỉ mặc định: ${e.toString()}',
      );
    }
  }

  @override
  Stream<List<AddressModel>> watchAddresses(String userId) {
    if (userId.trim().isEmpty) {
      return Stream.error(
        const AuthFailure('Bạn cần đăng nhập để theo dõi địa chỉ.'),
      );
    }
    final current = _userAddresses[userId] ?? [];
    final controller = _getController(userId);
    return Stream<List<AddressModel>>.value(List.unmodifiable(current))
        .concatWith([controller.stream]);
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}

extension _StreamConcat<T> on Stream<T> {
  Stream<T> concatWith(Iterable<Stream<T>> others) async* {
    yield* this;
    for (final stream in others) {
      yield* stream;
    }
  }
}

/// Provider for AddressRepository
final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  final repo = AddressRepositoryImpl();
  ref.onDispose(() => repo.dispose());
  return repo;
});
