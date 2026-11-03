import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/restaurant_config.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/address_model.dart';
import '../../data/repositories/geo_location_repository.dart';
import '../../domain/entities/resolved_location.dart';
import '../../domain/repositories/location_repository.dart';

@immutable
class LocationSelectionState {
  const LocationSelectionState({
    this.location,
    this.isLoading = false,
    this.errorMessage,
    this.isGeocodingConfigured = false,
  });

  final ResolvedLocation? location;
  final bool isLoading;
  final String? errorMessage;
  final bool isGeocodingConfigured;

  double? get distanceKm => location?.routeDistanceKm;
  double? get deliveryFee => RestaurantConfig.calculateDeliveryFee(distanceKm);
  bool get isServiceable =>
      distanceKm != null &&
      distanceKm! <= RestaurantConfig.maxDeliveryDistanceKm;

  LocationSelectionState copyWith({
    ResolvedLocation? location,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isGeocodingConfigured,
  }) {
    return LocationSelectionState(
      location: location ?? this.location,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isGeocodingConfigured:
          isGeocodingConfigured ?? this.isGeocodingConfigured,
    );
  }
}

class LocationSelectionViewModel extends Notifier<LocationSelectionState> {
  late LocationRepository _repository;
  int _requestId = 0;

  @override
  LocationSelectionState build() {
    _repository = ref.watch(locationRepositoryProvider);
    return LocationSelectionState(
      isGeocodingConfigured: _repository.isGeocodingConfigured,
    );
  }

  void initialize(AddressModel? address) {
    _requestId++;
    if (address?.latitude == null || address?.longitude == null) {
      state = LocationSelectionState(
        isGeocodingConfigured: _repository.isGeocodingConfigured,
      );
      return;
    }
    state = state.copyWith(
      location: ResolvedLocation(
        latitude: address!.latitude!,
        longitude: address.longitude!,
        formattedAddress: address.fullAddress,
        streetAddress: address.streetAddress,
        ward: address.ward,
        district: address.district,
        city: address.city,
        placeId: address.placeId,
        routeDistanceKm:
            address.routeDistanceKm ??
            RestaurantConfig.calculateDistanceToRestaurant(
              address.latitude!,
              address.longitude!,
            ),
      ),
    );
  }

  Future<void> useCurrentLocation() async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final location = await _repository.getCurrentLocation();
      if (requestId != _requestId) return;
      state = state.copyWith(location: location, isLoading: false);
    } catch (error) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: error is Failure ? error.message : error.toString(),
      );
    }
  }

  Future<bool> findAddress(String query) async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final location = await _repository.findAddress(query);
      if (requestId != _requestId) return false;
      state = state.copyWith(location: location, isLoading: false);
      return true;
    } catch (error) {
      if (requestId != _requestId) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: error is Failure ? error.message : error.toString(),
      );
      return false;
    }
  }

  Future<void> selectPoint({
    required double latitude,
    required double longitude,
  }) async {
    final requestId = ++_requestId;
    final preview = ResolvedLocation(
      latitude: latitude,
      longitude: longitude,
      formattedAddress: '',
      routeDistanceKm: RestaurantConfig.calculateDistanceToRestaurant(
        latitude,
        longitude,
      ),
    );
    state = state.copyWith(
      location: preview,
      isLoading: true,
      clearError: true,
    );
    try {
      final location = await _repository.resolveLocation(
        latitude: latitude,
        longitude: longitude,
      );
      if (requestId != _requestId) return;
      state = state.copyWith(location: location, isLoading: false);
    } catch (error) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: error is Failure ? error.message : error.toString(),
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final locationSelectionProvider =
    NotifierProvider<LocationSelectionViewModel, LocationSelectionState>(
      LocationSelectionViewModel.new,
    );
