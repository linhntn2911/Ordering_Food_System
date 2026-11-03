import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/restaurant_config.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/resolved_location.dart';
import '../../domain/repositories/location_repository.dart';

class GeoLocationRepository implements LocationRepository {
  GeoLocationRepository({http.Client? client, String? apiKey})
    : _client = client ?? http.Client(),
      _apiKey =
          apiKey ??
          const String.fromEnvironment('GEOAPIFY_API_KEY', defaultValue: '');

  static const _baseUrl = 'api.geoapify.com';

  final http.Client _client;
  final String _apiKey;

  @override
  bool get isGeocodingConfigured => _apiKey.trim().isNotEmpty;

  @override
  Future<ResolvedLocation> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const AddressFailure(
        'Dịch vụ vị trí đang tắt. Hãy bật GPS rồi thử lại.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const AddressFailure(
        'Bạn chưa cấp quyền vị trí. Bạn vẫn có thể chạm bản đồ để chọn địa chỉ.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const AddressFailure(
        'Quyền vị trí đã bị từ chối vĩnh viễn. Hãy bật lại trong Cài đặt hoặc chạm bản đồ để chọn địa chỉ.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    return resolveLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  @override
  Future<ResolvedLocation> findAddress(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < 5) {
      throw const AddressFailure(
        'Vui lòng nhập địa chỉ đầy đủ hơn để hệ thống tìm vị trí.',
      );
    }
    if (!isGeocodingConfigured) {
      throw const AddressFailure(
        'Chưa cấu hình Geoapify nên không thể tự tìm địa chỉ bằng chữ.',
      );
    }

    final uri = Uri.https(_baseUrl, '/v1/geocode/search', {
      'text': normalizedQuery,
      'format': 'json',
      'lang': 'vi',
      'limit': '1',
      'filter': 'countrycode:vn',
      'bias':
          'proximity:${RestaurantConfig.restaurantLng},${RestaurantConfig.restaurantLat}',
      'apiKey': _apiKey,
    });
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw const AddressFailure(
        'Không thể tìm địa chỉ lúc này. Hãy kiểm tra API key và kết nối mạng.',
      );
    }

    final item = _firstResult(
      response.body,
      emptyMessage:
          'Không tìm thấy địa chỉ. Hãy nhập rõ số nhà, đường, phường và quận.',
    );
    final address = _locationFromJson(item);
    final routeDistanceKm = await _routeDistance(
      latitude: address.latitude,
      longitude: address.longitude,
    );
    return address.copyWith(
      routeDistanceKm:
          routeDistanceKm ??
          RestaurantConfig.calculateDistanceToRestaurant(
            address.latitude,
            address.longitude,
          ),
    );
  }

  @override
  Future<ResolvedLocation> resolveLocation({
    required double latitude,
    required double longitude,
  }) async {
    final fallback = ResolvedLocation(
      latitude: latitude,
      longitude: longitude,
      formattedAddress: '',
      routeDistanceKm: RestaurantConfig.calculateDistanceToRestaurant(
        latitude,
        longitude,
      ),
    );

    if (!isGeocodingConfigured) {
      return fallback;
    }

    try {
      final results = await Future.wait<Object?>([
        _reverseGeocode(latitude: latitude, longitude: longitude),
        _routeDistance(latitude: latitude, longitude: longitude),
      ]);
      final address = results[0] as ResolvedLocation;
      final routeDistanceKm = results[1] as double?;
      return address.copyWith(
        routeDistanceKm: routeDistanceKm ?? fallback.routeDistanceKm,
      );
    } on AddressFailure {
      rethrow;
    } catch (_) {
      throw const AddressFailure(
        'Không thể nhận diện địa chỉ lúc này. Hãy kiểm tra mạng và thử lại.',
      );
    }
  }

  Future<ResolvedLocation> _reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(_baseUrl, '/v1/geocode/reverse', {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'format': 'json',
      'lang': 'vi',
      'apiKey': _apiKey,
    });
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw const AddressFailure('Dịch vụ nhận diện địa chỉ đang bận.');
    }

    final item = _firstResult(
      response.body,
      emptyMessage: 'Không tìm thấy địa chỉ tại vị trí đã chọn. Hãy đặt ghim gần đường hơn.',
    );
    return _locationFromJson(
      item,
      fallbackLatitude: latitude,
      fallbackLongitude: longitude,
    );
  }

  Map<String, dynamic> _firstResult(
    String responseBody, {
    required String emptyMessage,
  }) {
    final body = jsonDecode(responseBody) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>? ?? const [];
    if (results.isEmpty) throw AddressFailure(emptyMessage);
    return results.first as Map<String, dynamic>;
  }

  ResolvedLocation _locationFromJson(
    Map<String, dynamic> item, {
    double? fallbackLatitude,
    double? fallbackLongitude,
  }) {
    final latitude = (item['lat'] as num?)?.toDouble() ?? fallbackLatitude;
    final longitude = (item['lon'] as num?)?.toDouble() ?? fallbackLongitude;
    if (latitude == null || longitude == null) {
      throw const AddressFailure(
        'Kết quả địa chỉ không có tọa độ hợp lệ. Hãy nhập địa chỉ khác.',
      );
    }
    final street = [
      item['housenumber'] as String?,
      item['street'] as String?,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');

    return ResolvedLocation(
      latitude: latitude,
      longitude: longitude,
      formattedAddress: item['formatted'] as String? ?? '',
      streetAddress: street.isEmpty ? item['address_line1'] as String? : street,
      ward: item['suburb'] as String? ?? item['quarter'] as String?,
      district: item['district'] as String? ?? item['county'] as String?,
      city: item['city'] as String? ?? item['state'] as String?,
      placeId: item['place_id'] as String?,
    );
  }

  Future<double?> _routeDistance({
    required double latitude,
    required double longitude,
  }) async {
    final waypoints =
        '${RestaurantConfig.restaurantLat},${RestaurantConfig.restaurantLng}|$latitude,$longitude';
    final uri = Uri.https(_baseUrl, '/v1/routing', {
      'waypoints': waypoints,
      'mode': 'drive',
      'apiKey': _apiKey,
    });
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final features = body['features'] as List<dynamic>? ?? const [];
    if (features.isEmpty) return null;
    final feature = features.first as Map<String, dynamic>;
    final properties = feature['properties'] as Map<String, dynamic>?;
    final distanceMeters = (properties?['distance'] as num?)?.toDouble();
    return distanceMeters == null ? null : distanceMeters / 1000;
  }

  void dispose() => _client.close();
}

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final repository = GeoLocationRepository();
  ref.onDispose(repository.dispose);
  return repository;
});
