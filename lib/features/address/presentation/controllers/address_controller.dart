import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/errors/failures.dart';
import 'package:ordering_food_system/features/cart/presentation/controllers/cart_controller.dart';

import '../../data/address_repository.dart';
import '../../data/models/address_model.dart';

/// Immutable State for Address Feature
@immutable
class AddressState {
  final List<AddressModel> addresses;
  final String? selectedAddressId;
  final bool isLoading;
  final String? errorMessage;
  final String? userId;

  const AddressState({
    this.addresses = const [],
    this.selectedAddressId,
    this.isLoading = false,
    this.errorMessage,
    this.userId,
  });

  bool get isEmpty => addresses.isEmpty;
  bool get isNotEmpty => addresses.isNotEmpty;

  /// Retrieves the single default address (FR-018)
  AddressModel? get defaultAddress {
    return addresses.cast<AddressModel?>().firstWhere(
      (element) => element?.isDefault == true,
      orElse: () => addresses.isNotEmpty ? addresses.first : null,
    );
  }

  /// Retrieves currently active selected address for checkout
  AddressModel? get selectedAddress {
    if (selectedAddressId != null) {
      final found = addresses.cast<AddressModel?>().firstWhere(
        (element) => element?.id == selectedAddressId,
        orElse: () => null,
      );
      if (found != null) return found;
    }
    return defaultAddress;
  }

  AddressState copyWith({
    List<AddressModel>? addresses,
    String? selectedAddressId,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? userId,
  }) {
    return AddressState(
      addresses: addresses != null
          ? List.unmodifiable(addresses)
          : this.addresses,
      selectedAddressId: selectedAddressId ?? this.selectedAddressId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      userId: userId ?? this.userId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressState &&
          runtimeType == other.runtimeType &&
          listEquals(addresses, other.addresses) &&
          selectedAddressId == other.selectedAddressId &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage &&
          userId == other.userId;

  @override
  int get hashCode =>
      addresses.hashCode ^
      selectedAddressId.hashCode ^
      isLoading.hashCode ^
      errorMessage.hashCode ^
      userId.hashCode;
}

/// AddressController managing address lifecycle with Riverpod Notifier
class AddressController extends Notifier<AddressState> {
  late AddressRepository _repository;

  @override
  AddressState build() {
    _repository = ref.watch(addressRepositoryProvider);
    final userId = ref.watch(currentCustomerIdProvider);

    final initialAddresses = userId != null && userId.isNotEmpty
        ? _repository.getCachedAddresses(userId)
        : const <AddressModel>[];

    return AddressState(userId: userId, addresses: initialAddresses);
  }

  String _requireAuth() {
    final uid = state.userId;
    if (uid == null || uid.trim().isEmpty) {
      const error = 'Bạn cần đăng nhập để thao tác với địa chỉ.';
      state = state.copyWith(errorMessage: error);
      throw const AuthFailure(error);
    }
    return uid;
  }

  /// Load addresses for customer (FR-017)
  Future<void> loadAddresses([String? targetUserId]) async {
    final uid = targetUserId ?? state.userId;
    if (uid == null || uid.trim().isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repository.getAddresses(uid);
      state = state.copyWith(addresses: list, isLoading: false, userId: uid);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is Failure ? e.message : e.toString(),
      );
    }
  }

  /// Create and persist a new address (FR-017)
  Future<bool> addAddress(AddressModel address) async {
    final uid = _requireAuth();
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.addAddress(uid, address);
      final updatedList = await _repository.getAddresses(uid);
      state = state.copyWith(addresses: updatedList, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is Failure ? e.message : e.toString(),
      );
      return false;
    }
  }

  /// Update an existing delivery address (FR-017)
  Future<bool> updateAddress(AddressModel address) async {
    final uid = _requireAuth();
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.updateAddress(uid, address);
      final updatedList = await _repository.getAddresses(uid);
      state = state.copyWith(addresses: updatedList, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is Failure ? e.message : e.toString(),
      );
      return false;
    }
  }

  /// Delete an address from customer address book (FR-017)
  Future<bool> deleteAddress(String addressId) async {
    final uid = _requireAuth();
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.deleteAddress(uid, addressId);
      final updatedList = await _repository.getAddresses(uid);

      String? newSelectedId = state.selectedAddressId;
      if (newSelectedId == addressId) {
        newSelectedId = null;
      }

      state = state.copyWith(
        addresses: updatedList,
        selectedAddressId: newSelectedId,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is Failure ? e.message : e.toString(),
      );
      return false;
    }
  }

  /// Set selected address as the sole default address (FR-018, User Story 8 Scenario 2)
  Future<bool> setDefaultAddress(String addressId) async {
    final uid = _requireAuth();
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.setDefaultAddress(uid, addressId);
      final updatedList = await _repository.getAddresses(uid);
      state = state.copyWith(addresses: updatedList, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is Failure ? e.message : e.toString(),
      );
      return false;
    }
  }

  /// Select an address for checkout without changing permanent default status
  void selectAddress(String addressId) {
    state = state.copyWith(selectedAddressId: addressId);
  }

  /// Clear active error banner
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for AddressController
final addressControllerProvider =
    NotifierProvider<AddressController, AddressState>(AddressController.new);
