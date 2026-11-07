import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/restaurant_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/address_model.dart';
import '../../domain/entities/resolved_location.dart';
import '../viewmodels/address_controller.dart';
import '../viewmodels/location_selection_view_model.dart';

/// AddEditAddressScreen (Màn hình Thêm hoặc Sửa Địa chỉ - Member 3)
/// Xác thực đầy đủ form, tọa độ, cự ly và phí giao hàng theo SPEC.md
class AddEditAddressScreen extends ConsumerStatefulWidget {
  final AddressModel? initialAddress;

  const AddEditAddressScreen({super.key, this.initialAddress});

  @override
  ConsumerState<AddEditAddressScreen> createState() =>
      _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mapController = MapController();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _wardController;
  late TextEditingController _districtController;
  late TextEditingController _cityController;

  late FocusNode _nameFocus;
  late FocusNode _phoneFocus;
  late FocusNode _streetFocus;
  late FocusNode _wardFocus;
  late FocusNode _districtFocus;
  late FocusNode _cityFocus;

  String _selectedLabel = 'Nhà riêng';
  bool _isDefault = false;
  bool _isSubmitting = false;
  String? _lastResolvedAddressQuery;

  final List<String> _labelOptions = ['Nhà riêng', 'Văn phòng', 'Khác'];

  @override
  void initState() {
    super.initState();
    final item = widget.initialAddress;

    _nameController = TextEditingController(text: item?.recipientName ?? '');
    _phoneController = TextEditingController(text: item?.phoneNumber ?? '');
    _streetController = TextEditingController(text: item?.streetAddress ?? '');
    _wardController = TextEditingController(text: item?.ward ?? '');
    _districtController = TextEditingController(text: item?.district ?? '');
    _cityController = TextEditingController(
      text: item?.city ?? 'TP. Hồ Chí Minh',
    );

    _nameFocus = FocusNode();
    _phoneFocus = FocusNode();
    _streetFocus = FocusNode();
    _wardFocus = FocusNode();
    _districtFocus = FocusNode();
    _cityFocus = FocusNode();
    _selectedLabel = item?.label ?? 'Nhà riêng';
    _isDefault = item?.isDefault ?? false;

    Future.microtask(
      () => ref
          .read(locationSelectionProvider.notifier)
          .initialize(widget.initialAddress),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _wardController.dispose();
    _districtController.dispose();
    _cityController.dispose();

    _nameFocus.dispose();
    _phoneFocus.dispose();
    _streetFocus.dispose();
    _wardFocus.dispose();
    _districtFocus.dispose();
    _cityFocus.dispose();
    super.dispose();
  }

  void _applyResolvedLocation(ResolvedLocation location) {
    if (location.streetAddress?.trim().isNotEmpty == true) {
      _streetController.text = location.streetAddress!.trim();
    }
    if (location.ward?.trim().isNotEmpty == true) {
      _wardController.text = location.ward!.trim();
    }
    if (location.district?.trim().isNotEmpty == true) {
      _districtController.text = location.district!.trim();
    }
    if (location.city?.trim().isNotEmpty == true) {
      _cityController.text = location.city!.trim();
    }
    _lastResolvedAddressQuery = _normalizedAddressQuery;
    _mapController.move(LatLng(location.latitude, location.longitude), 16);
  }

  String get _addressQuery => [
    _streetController.text.trim(),
    _wardController.text.trim(),
    _districtController.text.trim(),
    _cityController.text.trim(),
    'Việt Nam',
  ].where((part) => part.isNotEmpty).join(', ');

  String get _normalizedAddressQuery =>
      _addressQuery.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    var locationState = ref.read(locationSelectionProvider);
    var location = locationState.location;
    var distance = locationState.distanceKm;
    final typedAddressChanged =
        _lastResolvedAddressQuery != null &&
        _normalizedAddressQuery != _lastResolvedAddressQuery;

    if (location == null || typedAddressChanged) {
      setState(() => _isSubmitting = true);
      final found = await ref
          .read(locationSelectionProvider.notifier)
          .findAddress(_addressQuery);
      if (!mounted) return;
      locationState = ref.read(locationSelectionProvider);
      location = locationState.location;
      distance = locationState.distanceKm;

      if (!found || location == null || distance == null) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              locationState.errorMessage ??
                  'Không thể tự xác định vị trí từ địa chỉ đã nhập.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      _applyResolvedLocation(location);
    }

    if (distance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng dùng vị trí hiện tại hoặc chạm bản đồ để chọn điểm giao hàng.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      if (_isSubmitting) setState(() => _isSubmitting = false);
      return;
    }
    if (distance > RestaurantConfig.maxDeliveryDistanceKm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Địa chỉ cách quán ${distance.toStringAsFixed(1)}km, vượt quá bán kính 8km. Vui lòng chọn địa chỉ khác.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      if (_isSubmitting) setState(() => _isSubmitting = false);
      return;
    }

    if (!_isSubmitting) setState(() => _isSubmitting = true);

    final address = AddressModel(
      id: widget.initialAddress?.id ?? '',
      userId: widget.initialAddress?.userId ?? '',
      label: _selectedLabel,
      recipientName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      streetAddress: location.streetAddress?.trim().isNotEmpty == true
          ? location.streetAddress!.trim()
          : _streetController.text.trim(),
      ward: location.ward?.trim().isNotEmpty == true
          ? location.ward!.trim()
          : _wardController.text.trim(),
      district: location.district?.trim().isNotEmpty == true
          ? location.district!.trim()
          : _districtController.text.trim(),
      city: location.city?.trim().isNotEmpty == true
          ? location.city!.trim()
          : _cityController.text.trim(),
      latitude: location.latitude,
      longitude: location.longitude,
      placeId: location.placeId,
      locationProvider: locationState.isGeocodingConfigured
          ? 'geoapify'
          : 'device',
      routeDistanceKm: distance,
      isDefault: _isDefault,
      createdAt: widget.initialAddress?.createdAt ?? DateTime.now(),
    );

    final controller = ref.read(addressControllerProvider.notifier);
    bool success;

    if (widget.initialAddress == null) {
      success = await controller.addAddress(address);
    } else {
      success = await controller.updateAddress(address);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialAddress == null
                ? 'Đã thêm địa chỉ giao hàng thành công!'
                : 'Đã cập nhật địa chỉ thành công!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).maybePop(address);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialAddress != null;
    final locationState = ref.watch(locationSelectionProvider);
    final distance = locationState.distanceKm;
    final deliveryFee = locationState.deliveryFee;

    ref.listen<LocationSelectionState>(locationSelectionProvider, (
      previous,
      next,
    ) {
      final location = next.location;
      if (location != null && location != previous?.location) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _applyResolvedLocation(location);
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Chỉnh sửa địa chỉ' : 'Thêm địa chỉ mới',
          style: AppTextStyles.headlineMedium,
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s24,
              vertical: AppSpacing.s16,
            ),
            children: [
              // Label selection chips
              Text(
                'Loại địa chỉ',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Row(
                children: _labelOptions.map((opt) {
                  final isSelected = _selectedLabel == opt;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.s8),
                    child: ChoiceChip(
                      label: Text(opt),
                      selected: isSelected,
                      selectedColor: AppColors.primarySoft,
                      backgroundColor: AppColors.surfaceMuted,
                      labelStyle: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: isSelected
                            ? AppColors.primaryEnd
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.radiusPill,
                      ),
                      onSelected: (_) => setState(() => _selectedLabel = opt),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.s20),

              // Recipient Name
              _buildFieldLabel('Tên người nhận *'),
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocus,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  hint: 'Nguyễn Văn A',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên người nhận';
                  }
                  if (val.trim().length < 2) {
                    return 'Tên người nhận phải có ít nhất 2 ký tự';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.s16),

              // Phone number
              _buildFieldLabel('Số điện thoại *'),
              TextFormField(
                controller: _phoneController,
                focusNode: _phoneFocus,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: _inputDecoration(
                  hint: '0901234567',
                  prefixIcon: Icons.phone_outlined,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  if (!AddressModel.isValidPhone(val)) {
                    return 'Số điện thoại không hợp lệ (10 số, đầu 03, 05, 07, 08, 09)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.s24),

              _buildLocationPicker(
                state: locationState,
                distance: distance,
                deliveryFee: deliveryFee,
              ),

              const SizedBox(height: AppSpacing.s20),

              // Detailed Street Address
              _buildFieldLabel('Số nhà, tên đường *'),
              TextFormField(
                controller: _streetController,
                focusNode: _streetFocus,
                keyboardType: TextInputType.streetAddress,
                decoration: _inputDecoration(
                  hint: 'Số 45 Lê Duẩn, Tòa nhà Diamond',
                  prefixIcon: Icons.location_on_outlined,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập địa chỉ chi tiết';
                  }
                  if (val.trim().length < 5) {
                    return 'Địa chỉ chi tiết phải có ít nhất 5 ký tự';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.s16),

              // Ward, District, City
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Phường / Xã'),
                        TextFormField(
                          controller: _wardController,
                          focusNode: _wardFocus,
                          keyboardType: TextInputType.text,
                          decoration: _inputDecoration(hint: 'Bến Nghé'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Quận / Huyện'),
                        TextFormField(
                          controller: _districtController,
                          focusNode: _districtFocus,
                          keyboardType: TextInputType.text,
                          decoration: _inputDecoration(hint: 'Quận 1'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.s16),

              _buildFieldLabel('Tỉnh / Thành phố'),
              TextFormField(
                controller: _cityController,
                focusNode: _cityFocus,
                keyboardType: TextInputType.text,
                decoration: _inputDecoration(hint: 'TP. Hồ Chí Minh'),
              ),

              const SizedBox(height: AppSpacing.s20),

              // Default address switch (FR-018)
              SwitchListTile(
                value: _isDefault,
                activeThumbColor: AppColors.primaryEnd,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Đặt làm địa chỉ mặc định',
                  style: AppTextStyles.titleMedium,
                ),
                subtitle: const Text(
                  'Địa chỉ này sẽ tự động được chọn khi bạn tiến hành thanh toán giỏ hàng.',
                  style: AppTextStyles.bodySmall,
                ),
                onChanged: (val) => setState(() => _isDefault = val),
              ),

              const SizedBox(height: AppSpacing.s32),

              // Submit Button
              GestureDetector(
                onTap: _isSubmitting ? null : _submitForm,
                child: Container(
                  height: 56,
                  decoration: const BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: AppRadii.radiusInput,
                    boxShadow: [AppShadows.primaryShadow],
                  ),
                  alignment: Alignment.center,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isEditing ? 'Lưu thay đổi' : 'Thêm địa chỉ',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Text(
        label,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLocationPicker({
    required LocationSelectionState state,
    required double? distance,
    required double? deliveryFee,
  }) {
    final location = state.location;
    final center = location == null
        ? const LatLng(
            RestaurantConfig.restaurantLat,
            RestaurantConfig.restaurantLng,
          )
        : LatLng(location.latitude, location.longitude);
    final isServiceable =
        distance != null && distance <= RestaurantConfig.maxDeliveryDistanceKm;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadii.radiusCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_searching_rounded,
                color: AppColors.primarySolid,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  'Chọn vị trí giao hàng',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Dùng GPS hoặc chạm bản đồ để đặt ghim. Hãy kiểm tra lại số nhà trước khi lưu.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () => ref
                        .read(locationSelectionProvider.notifier)
                        .useCurrentLocation(),
              icon: state.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(
                state.isLoading
                    ? 'Đang xác định vị trí...'
                    : 'Dùng vị trí hiện tại',
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primarySolid,
                disabledBackgroundColor: AppColors.primarySolid.withValues(
                  alpha: 0.55,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.radiusInput,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          ClipRRect(
            borderRadius: AppRadii.radiusMedium,
            child: SizedBox(
              height: 260,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: location == null ? 14 : 16,
                  minZoom: 10,
                  maxZoom: 19,
                  onTap: (_, point) => ref
                      .read(locationSelectionProvider.notifier)
                      .selectPoint(
                        latitude: point.latitude,
                        longitude: point.longitude,
                      ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.ordering_food_system',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: const LatLng(
                          RestaurantConfig.restaurantLat,
                          RestaurantConfig.restaurantLng,
                        ),
                        width: 42,
                        height: 42,
                        child: const Tooltip(
                          message: RestaurantConfig.name,
                          child: Icon(
                            Icons.storefront_rounded,
                            size: 34,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                      if (location != null)
                        Marker(
                          point: center,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_pin,
                            size: 46,
                            color: AppColors.primaryEnd,
                          ),
                        ),
                    ],
                  ),
                  const SimpleAttributionWidget(
                    source: Text('© OpenStreetMap contributors'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Chạm đúng vị trí cổng hoặc mặt tiền nơi nhận hàng.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (!state.isGeocodingConfigured) ...[
            const SizedBox(height: AppSpacing.s8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.s12),
              decoration: const BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: AppRadii.radiusMedium,
              ),
              child: Text(
                'Chưa cấu hình GEOAPIFY_API_KEY nên app chỉ lấy GPS và tính khoảng cách đường chim bay; địa chỉ sẽ không tự điền.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.s8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.s12),
              decoration: const BoxDecoration(
                color: AppColors.errorSoft,
                borderRadius: AppRadii.radiusMedium,
              ),
              child: Text(
                state.errorMessage!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ],
          if (location?.formattedAddress.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.s12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 20,
                  color: AppColors.primaryEnd,
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text(
                    location!.formattedAddress,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          if (distance != null) ...[
            const SizedBox(height: AppSpacing.s12),
            Container(
              padding: const EdgeInsets.all(AppSpacing.s12),
              decoration: BoxDecoration(
                color: isServiceable
                    ? AppColors.primarySoft
                    : AppColors.errorSoft,
                borderRadius: AppRadii.radiusMedium,
              ),
              child: Row(
                children: [
                  Icon(
                    isServiceable
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: isServiceable
                        ? AppColors.primaryEnd
                        : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Khoảng cách: ${distance.toStringAsFixed(1)} km',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isServiceable
                                ? AppColors.primaryEnd
                                : AppColors.error,
                          ),
                        ),
                        Text(
                          isServiceable
                              ? 'Phí giao dự kiến: ${CurrencyFormatter.formatVND(deliveryFee ?? 0)}'
                              : 'Ngoài bán kính phục vụ ${RestaurantConfig.maxDeliveryDistanceKm.toStringAsFixed(0)} km.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isServiceable
                                ? AppColors.textPrimary
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.textMuted, size: 20)
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s16,
      ),
      border: const OutlineInputBorder(
        borderRadius: AppRadii.radiusInput,
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppRadii.radiusInput,
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadii.radiusInput,
        borderSide: BorderSide(color: AppColors.primaryEnd, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppRadii.radiusInput,
        borderSide: BorderSide(color: AppColors.error),
      ),
    );
  }
}
