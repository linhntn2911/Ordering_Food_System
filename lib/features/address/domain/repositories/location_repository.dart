import '../entities/resolved_location.dart';

abstract class LocationRepository {
  bool get isGeocodingConfigured;

  Future<ResolvedLocation> getCurrentLocation();

  Future<ResolvedLocation> findAddress(String query);

  Future<ResolvedLocation> resolveLocation({
    required double latitude,
    required double longitude,
  });
}
