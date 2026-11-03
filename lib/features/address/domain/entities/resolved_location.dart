import 'package:flutter/foundation.dart';

@immutable
class ResolvedLocation {
  const ResolvedLocation({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.streetAddress,
    this.ward,
    this.district,
    this.city,
    this.placeId,
    this.routeDistanceKm,
  });

  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String? streetAddress;
  final String? ward;
  final String? district;
  final String? city;
  final String? placeId;
  final double? routeDistanceKm;

  ResolvedLocation copyWith({double? routeDistanceKm}) {
    return ResolvedLocation(
      latitude: latitude,
      longitude: longitude,
      formattedAddress: formattedAddress,
      streetAddress: streetAddress,
      ward: ward,
      district: district,
      city: city,
      placeId: placeId,
      routeDistanceKm: routeDistanceKm ?? this.routeDistanceKm,
    );
  }
}
