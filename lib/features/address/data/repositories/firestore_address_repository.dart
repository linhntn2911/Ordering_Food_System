import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/failures.dart';
import '../address_repository.dart';
import '../models/address_model.dart';

/// Firestore-backed address book scoped to the authenticated customer's UID.
class FirestoreAddressRepository implements AddressRepository {
  FirestoreAddressRepository(this._firestore);

  final FirebaseFirestore _firestore;
  final Map<String, List<AddressModel>> _cache = {};

  CollectionReference<Map<String, dynamic>> _addresses(String userId) {
    return _firestore.collection('users').doc(userId).collection('addresses');
  }

  void _requireUser(String userId) {
    if (userId.trim().isEmpty) {
      throw const AuthFailure('Bạn cần đăng nhập để thao tác với địa chỉ.');
    }
  }

  AddressModel _fromDocument(
    String userId,
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = Map<String, dynamic>.from(document.data() ?? const {});
    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];
    data
      ..['id'] = document.id
      ..['userId'] = userId
      ..['createdAt'] = createdAt is Timestamp
          ? createdAt.toDate().toIso8601String()
          : createdAt
      ..['updatedAt'] = updatedAt is Timestamp
          ? updatedAt.toDate().toIso8601String()
          : updatedAt;
    return AddressModel.fromMap(data);
  }

  List<AddressModel> _modelsFromSnapshot(
    String userId,
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final models =
        snapshot.docs
            .map((document) => _fromDocument(userId, document))
            .toList()
          ..sort((a, b) {
            if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
            return b.createdAt.compareTo(a.createdAt);
          });
    _cache[userId] = List.unmodifiable(models);
    return List.unmodifiable(models);
  }

  Map<String, dynamic> _writeData(
    String userId,
    AddressModel address, {
    required bool includeCreatedAt,
  }) {
    return <String, dynamic>{
      'userId': userId,
      'label': address.label.trim(),
      'recipientName': address.recipientName.trim(),
      'phoneNumber': address.phoneNumber.trim(),
      'streetAddress': address.streetAddress.trim(),
      if (address.ward?.trim().isNotEmpty == true) 'ward': address.ward!.trim(),
      if (address.district?.trim().isNotEmpty == true)
        'district': address.district!.trim(),
      if (address.city?.trim().isNotEmpty == true) 'city': address.city!.trim(),
      if (address.latitude != null) 'latitude': address.latitude,
      if (address.longitude != null) 'longitude': address.longitude,
      if (address.placeId?.trim().isNotEmpty == true)
        'placeId': address.placeId!.trim(),
      if (address.locationProvider?.trim().isNotEmpty == true)
        'locationProvider': address.locationProvider!.trim(),
      if (address.routeDistanceKm != null)
        'routeDistanceKm': address.routeDistanceKm,
      'isDefault': address.isDefault,
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getSnapshot(String userId) {
    return _addresses(userId).get();
  }

  @override
  List<AddressModel> getCachedAddresses(String userId) {
    return List.unmodifiable(_cache[userId] ?? const <AddressModel>[]);
  }

  @override
  Future<List<AddressModel>> getAddresses(String userId) async {
    _requireUser(userId);
    try {
      return _modelsFromSnapshot(userId, await _getSnapshot(userId));
    } catch (error) {
      throw AddressFailure('Lỗi khi tải danh sách địa chỉ: $error');
    }
  }

  @override
  Future<AddressModel?> getDefaultAddress(String userId) async {
    final addresses = await getAddresses(userId);
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (address) => address.isDefault,
      orElse: () => addresses.first,
    );
  }

  @override
  Future<void> addAddress(String userId, AddressModel address) async {
    _requireUser(userId);
    final errors = address.getValidationErrors();
    if (errors.isNotEmpty) throw ValidationFailure(errors.first);

    try {
      final snapshot = await _getSnapshot(userId);
      final shouldBeDefault = address.isDefault || snapshot.docs.isEmpty;
      final reference = address.id.trim().isEmpty
          ? _addresses(userId).doc()
          : _addresses(userId).doc(address.id);
      final batch = _firestore.batch();

      if (shouldBeDefault) {
        for (final document in snapshot.docs) {
          if (document.data()['isDefault'] == true) {
            batch.update(document.reference, {
              'isDefault': false,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
      batch.set(
        reference,
        _writeData(
          userId,
          address.copyWith(isDefault: shouldBeDefault),
          includeCreatedAt: true,
        ),
      );
      await batch.commit();
      await getAddresses(userId);
    } catch (error) {
      if (error is Failure) rethrow;
      throw AddressFailure('Lỗi khi thêm địa chỉ: $error');
    }
  }

  @override
  Future<void> updateAddress(String userId, AddressModel address) async {
    _requireUser(userId);
    final errors = address.getValidationErrors();
    if (errors.isNotEmpty) throw ValidationFailure(errors.first);

    try {
      final snapshot = await _getSnapshot(userId);
      final target = snapshot.docs
          .where((doc) => doc.id == address.id)
          .firstOrNull;
      if (target == null) {
        throw const AddressFailure('Không tìm thấy địa chỉ cần cập nhật.');
      }

      final otherDocuments = snapshot.docs.where((doc) => doc.id != address.id);
      final shouldBeDefault =
          address.isDefault ||
          (!otherDocuments.any((doc) => doc.data()['isDefault'] == true));
      final batch = _firestore.batch();
      if (shouldBeDefault) {
        for (final document in otherDocuments) {
          if (document.data()['isDefault'] == true) {
            batch.update(document.reference, {
              'isDefault': false,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
      batch.update(
        target.reference,
        _writeData(
          userId,
          address.copyWith(isDefault: shouldBeDefault),
          includeCreatedAt: false,
        ),
      );
      await batch.commit();
      await getAddresses(userId);
    } catch (error) {
      if (error is Failure) rethrow;
      throw AddressFailure('Lỗi khi cập nhật địa chỉ: $error');
    }
  }

  @override
  Future<void> deleteAddress(String userId, String addressId) async {
    _requireUser(userId);
    try {
      final snapshot = await _getSnapshot(userId);
      final target = snapshot.docs
          .where((doc) => doc.id == addressId)
          .firstOrNull;
      if (target == null) return;

      final remaining = snapshot.docs
          .where((doc) => doc.id != addressId)
          .toList();
      final batch = _firestore.batch()..delete(target.reference);
      if (target.data()['isDefault'] == true && remaining.isNotEmpty) {
        batch.update(remaining.first.reference, {
          'isDefault': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      await getAddresses(userId);
    } catch (error) {
      if (error is Failure) rethrow;
      throw AddressFailure('Lỗi khi xóa địa chỉ: $error');
    }
  }

  @override
  Future<void> setDefaultAddress(String userId, String addressId) async {
    _requireUser(userId);
    try {
      final snapshot = await _getSnapshot(userId);
      if (!snapshot.docs.any((doc) => doc.id == addressId)) {
        throw const AddressFailure('Không tìm thấy địa chỉ được chọn.');
      }
      final batch = _firestore.batch();
      for (final document in snapshot.docs) {
        final isDefault = document.id == addressId;
        if (document.data()['isDefault'] != isDefault) {
          batch.update(document.reference, {
            'isDefault': isDefault,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      await batch.commit();
      await getAddresses(userId);
    } catch (error) {
      if (error is Failure) rethrow;
      throw AddressFailure('Lỗi khi thiết lập địa chỉ mặc định: $error');
    }
  }

  @override
  Stream<List<AddressModel>> watchAddresses(String userId) {
    _requireUser(userId);
    return _addresses(userId)
        .snapshots()
        .map((snapshot) => _modelsFromSnapshot(userId, snapshot));
  }
}
