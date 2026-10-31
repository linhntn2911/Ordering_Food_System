import 'package:flutter/foundation.dart';

import '../../../../core/config/restaurant_config.dart';

/// Address model adhering to FR-014, FR-017, FR-018, BR-008, FR-046, FR-048
@immutable
class AddressModel {
  final String id;
  final String userId; // Isolated customer UID (BR-008)
  final String label; // e.g., 'Nhà riêng', 'Văn phòng', 'Khác'
  final String recipientName; // Recipient full name (FR-014)
  final String phoneNumber; // Valid recipient phone number (FR-014)
  final String streetAddress; // Detailed street / house number
  final String? ward; // Phường / Xã
  final String? district; // Quận / Huyện
  final String? city; // Tỉnh / Thành phố
  final double? latitude; // Latitude for distance calculation (FR-046)
  final double? longitude; // Longitude for distance calculation (FR-046)
  final bool isDefault; // Exactly one default address per customer (FR-018)
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AddressModel({
    required this.id,
    required this.userId,
    this.label = 'Nhà riêng',
    required this.recipientName,
    required this.phoneNumber,
    required this.streetAddress,
    this.ward,
    this.district,
    this.city,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Formatted complete address string
  String get fullAddress {
    final parts = [
      streetAddress,
      if (ward != null && ward!.trim().isNotEmpty) ward!,
      if (district != null && district!.trim().isNotEmpty) district!,
      if (city != null && city!.trim().isNotEmpty) city!,
    ];
    return parts.join(', ');
  }

  /// Calculates authoritative distance to the restaurant in kilometers (FR-046)
  double? get distanceToRestaurant {
    if (latitude == null || longitude == null) return null;
    return RestaurantConfig.calculateDistanceToRestaurant(
      latitude!,
      longitude!,
    );
  }

  /// Checks if address is within allowable delivery service radius (<= 8km) (FR-048)
  bool get isServiceable {
    final dist = distanceToRestaurant;
    return dist != null && dist <= RestaurantConfig.maxDeliveryDistanceKm;
  }

  /// Calculated delivery fee based on distance bands (FR-047)
  double? get deliveryFee =>
      RestaurantConfig.calculateDeliveryFee(distanceToRestaurant);

  /// Validates format of recipient phone number (Vietnamese standard 10 digits)
  static bool isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    final regex = RegExp(r'^(0[3|5|7|8|9])[0-9]{8}$');
    return regex.hasMatch(cleaned);
  }

  /// Validates required fields for address persistence
  List<String> getValidationErrors() {
    final errors = <String>[];
    if (recipientName.trim().isEmpty) {
      errors.add('Tên người nhận không được để trống.');
    } else if (recipientName.trim().length < 2) {
      errors.add('Tên người nhận phải có ít nhất 2 ký tự.');
    }

    if (phoneNumber.trim().isEmpty) {
      errors.add('Số điện thoại không được để trống.');
    } else if (!isValidPhone(phoneNumber)) {
      errors.add(
        'Số điện thoại không hợp lệ (cần đúng 10 số đầu 03, 05, 07, 08, 09).',
      );
    }

    if (streetAddress.trim().isEmpty) {
      errors.add('Địa chỉ chi tiết không được để trống.');
    } else if (streetAddress.trim().length < 5) {
      errors.add('Địa chỉ chi tiết phải có ít nhất 5 ký tự.');
    }

    if (latitude != null && longitude != null) {
      if (!isServiceable) {
        errors.add(
          'Địa chỉ này cách nhà hàng ${(distanceToRestaurant ?? 0).toStringAsFixed(1)}km, vượt quá bán kính phục vụ 8km.',
        );
      }
    }

    return errors;
  }

  bool get isValid => getValidationErrors().isEmpty;

  AddressModel copyWith({
    String? id,
    String? userId,
    String? label,
    String? recipientName,
    String? phoneNumber,
    String? streetAddress,
    String? ward,
    String? district,
    String? city,
    double? latitude,
    double? longitude,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      streetAddress: streetAddress ?? this.streetAddress,
      ward: ward ?? this.ward,
      district: district ?? this.district,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'label': label,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'streetAddress': streetAddress,
      'ward': ward,
      'district': district,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      label: map['label'] as String? ?? 'Nhà riêng',
      recipientName: map['recipientName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      streetAddress: map['streetAddress'] as String? ?? '',
      ward: map['ward'] as String?,
      district: map['district'] as String?,
      city: map['city'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          label == other.label &&
          recipientName == other.recipientName &&
          phoneNumber == other.phoneNumber &&
          streetAddress == other.streetAddress &&
          isDefault == other.isDefault &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      recipientName.hashCode ^
      phoneNumber.hashCode ^
      isDefault.hashCode;
}
