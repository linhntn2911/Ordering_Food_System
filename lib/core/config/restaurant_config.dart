import 'dart:math' as math;

/// Restaurant coordinates and delivery fee calculation rules according to SPEC.md (FR-046, FR-047, FR-048)
class RestaurantConfig {
  static const String name = 'Food Ninja Restaurant';
  static const String address =
      '123 Nguyen Hue, Ben Nghe, District 1, Ho Chi Minh City';

  // Restaurant reference location (District 1, HCMC)
  static const double restaurantLat = 10.7769;
  static const double restaurantLng = 106.7009;

  /// Maximum permitted delivery radius according to SRS and SPEC.md (8 km)
  static const double maxDeliveryDistanceKm = 8.0;

  /// Haversine formula to compute great-circle distance between two points in km
  static double calculateDistanceInKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degreesToRadians(endLat - startLat);
    final double dLng = _degreesToRadians(endLng - startLng);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(startLat)) *
            math.cos(_degreesToRadians(endLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Distance from restaurant to customer coordinates
  static double calculateDistanceToRestaurant(double lat, double lng) {
    return calculateDistanceInKm(
      startLat: restaurantLat,
      startLng: restaurantLng,
      endLat: lat,
      endLng: lng,
    );
  }

  /// Calculate delivery fee according to FR-047 & FR-048:
  /// - <= 3 km: 15,000 VND
  /// - > 3 km and <= 5 km: 20,000 VND
  /// - > 5 km and <= 8 km: 30,000 VND
  /// - > 8 km or null: null (unserviceable, blocked)
  static double? calculateDeliveryFee(double? distanceInKm) {
    if (distanceInKm == null || distanceInKm < 0) return null;
    if (distanceInKm > maxDeliveryDistanceKm) return null;

    if (distanceInKm <= 3.0) {
      return 15000.0;
    } else if (distanceInKm <= 5.0) {
      return 20000.0;
    } else {
      return 30000.0;
    }
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }
}
