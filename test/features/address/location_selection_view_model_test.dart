import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/errors/failures.dart';
import 'package:ordering_food_system/features/address/data/repositories/geo_location_repository.dart';
import 'package:ordering_food_system/features/address/domain/entities/resolved_location.dart';
import 'package:ordering_food_system/features/address/domain/repositories/location_repository.dart';
import 'package:ordering_food_system/features/address/presentation/viewmodels/location_selection_view_model.dart';

class _FakeLocationRepository implements LocationRepository {
  _FakeLocationRepository({this.failure});

  final AddressFailure? failure;

  @override
  bool get isGeocodingConfigured => true;

  @override
  Future<ResolvedLocation> findAddress(String query) async {
    if (failure != null) throw failure!;
    return const ResolvedLocation(
      latitude: 10.7824,
      longitude: 106.6981,
      formattedAddress: '34 Lê Duẩn, Bến Nghé, Quận 1, TP. Hồ Chí Minh',
      streetAddress: '34 Lê Duẩn',
      ward: 'Bến Nghé',
      district: 'Quận 1',
      city: 'TP. Hồ Chí Minh',
      placeId: 'diamond-plaza',
      routeDistanceKm: 2.1,
    );
  }

  @override
  Future<ResolvedLocation> getCurrentLocation() async {
    if (failure != null) throw failure!;
    return const ResolvedLocation(
      latitude: 10.78,
      longitude: 106.70,
      formattedAddress: '12 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh',
      streetAddress: '12 Nguyễn Huệ',
      district: 'Quận 1',
      city: 'TP. Hồ Chí Minh',
      routeDistanceKm: 2.4,
    );
  }

  @override
  Future<ResolvedLocation> resolveLocation({
    required double latitude,
    required double longitude,
  }) async {
    if (failure != null) throw failure!;
    return ResolvedLocation(
      latitude: latitude,
      longitude: longitude,
      formattedAddress: 'Vị trí đã chọn',
      routeDistanceKm: 6.2,
    );
  }
}

void main() {
  test(
    'GPS success exposes resolved address, route distance, and fee',
    () async {
      final container = ProviderContainer(
        overrides: [
          locationRepositoryProvider.overrideWithValue(
            _FakeLocationRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(locationSelectionProvider.notifier)
          .useCurrentLocation();

      final state = container.read(locationSelectionProvider);
      expect(state.location?.streetAddress, '12 Nguyễn Huệ');
      expect(state.distanceKm, 2.4);
      expect(state.deliveryFee, 15000);
      expect(state.isServiceable, isTrue);
      expect(state.errorMessage, isNull);
    },
  );

  test('map selection recalculates route distance and fee', () async {
    final container = ProviderContainer(
      overrides: [
        locationRepositoryProvider.overrideWithValue(_FakeLocationRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(locationSelectionProvider.notifier)
        .selectPoint(latitude: 10.73, longitude: 106.71);

    final state = container.read(locationSelectionProvider);
    expect(state.location?.formattedAddress, 'Vị trí đã chọn');
    expect(state.distanceKm, 6.2);
    expect(state.deliveryFee, 30000);
  });

  test(
    'typed address is automatically converted into a delivery pin',
    () async {
      final container = ProviderContainer(
        overrides: [
          locationRepositoryProvider.overrideWithValue(
            _FakeLocationRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final found = await container
          .read(locationSelectionProvider.notifier)
          .findAddress(
            '34 Lê Duẩn, Bến Nghé, Quận 1, TP. Hồ Chí Minh, Việt Nam',
          );

      final state = container.read(locationSelectionProvider);
      expect(found, isTrue);
      expect(state.location?.placeId, 'diamond-plaza');
      expect(state.distanceKm, 2.1);
      expect(state.deliveryFee, 15000);
    },
  );

  test('failed typed-address lookup exposes a correction message', () async {
    final container = ProviderContainer(
      overrides: [
        locationRepositoryProvider.overrideWithValue(
          _FakeLocationRepository(
            failure: const AddressFailure('Không tìm thấy địa chỉ.'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final found = await container
        .read(locationSelectionProvider.notifier)
        .findAddress('địa chỉ không tồn tại');

    final state = container.read(locationSelectionProvider);
    expect(found, isFalse);
    expect(state.location, isNull);
    expect(state.errorMessage, 'Không tìm thấy địa chỉ.');
  });

  test('permission or service failure remains recoverable', () async {
    final container = ProviderContainer(
      overrides: [
        locationRepositoryProvider.overrideWithValue(
          _FakeLocationRepository(
            failure: const AddressFailure('Bạn chưa cấp quyền vị trí.'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(locationSelectionProvider.notifier)
        .useCurrentLocation();

    final state = container.read(locationSelectionProvider);
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, 'Bạn chưa cấp quyền vị trí.');
  });
}
