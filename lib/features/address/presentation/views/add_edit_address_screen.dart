import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/restaurant_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/address_model.dart';
import '../controllers/address_controller.dart';

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

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _wardController;
  late TextEditingController _districtController;
  late TextEditingController _cityController;
  late TextEditingController _latController;
  late TextEditingController _lngController;

  String _selectedLabel = 'Nhà riêng';
  bool _isDefault = false;
  bool _isSubmitting = false;

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
    _latController = TextEditingController(
      text: item?.latitude != null ? item!.latitude.toString() : '10.7720',
    );
    _lngController = TextEditingController(
      text: item?.longitude != null ? item!.longitude.toString() : '106.6980',
    );

    _selectedLabel = item?.label ?? 'Nhà riêng';
    _isDefault = item?.isDefault ?? false;

    _latController.addListener(() => setState(() {}));
    _lngController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _wardController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  double? get _currentDistance {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null) return null;
    return RestaurantConfig.calculateDistanceToRestaurant(lat, lng);
  }

  double? get _currentDeliveryFee =>
      RestaurantConfig.calculateDeliveryFee(_currentDistance);

  void _applyPresetLocation(String name, double lat, double lng) {
    setState(() {
      _latController.text = lat.toString();
      _lngController.text = lng.toString();
      if (_districtController.text.isEmpty) {
        _districtController.text = name;
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    final distance = _currentDistance;
    if (distance != null && distance > RestaurantConfig.maxDeliveryDistanceKm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Địa chỉ cách quán ${distance.toStringAsFixed(1)}km, vượt quá bán kính 8km. Vui lòng chọn địa chỉ khác.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final address = AddressModel(
      id: widget.initialAddress?.id ?? '',
      userId: widget.initialAddress?.userId ?? '',
      label: _selectedLabel,
      recipientName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      streetAddress: _streetController.text.trim(),
      ward: _wardController.text.trim(),
      district: _districtController.text.trim(),
      city: _cityController.text.trim(),
      latitude: lat,
      longitude: lng,
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
    final distance = _currentDistance;
    final deliveryFee = _currentDeliveryFee;

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

              const SizedBox(height: AppSpacing.s16),

              // Detailed Street Address
              _buildFieldLabel('Số nhà, tên đường *'),
              TextFormField(
                controller: _streetController,
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
                decoration: _inputDecoration(hint: 'TP. Hồ Chí Minh'),
              ),

              const SizedBox(height: AppSpacing.s24),

              // Coordinates and Serviceability Section (FR-046, FR-048)
              Container(
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
                          Icons.radar_rounded,
                          color: AppColors.primarySolid,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Text(
                          'Tọa độ & Cự ly giao hàng (FR-046)',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'Tọa độ giúp xác định chính xác khoảng cách đến quán để tính phí giao hàng (Tối đa 8km).',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),

                    // Preset buttons for convenience
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s4,
                      children: [
                        _presetChip('Quận 1 (~1.2km)', 10.7720, 106.6980),
                        _presetChip('Quận 3 (~2.8km)', 10.7850, 106.6850),
                        _presetChip('Quận 7 (~6.2km)', 10.7320, 106.7150),
                        _presetChip('Thủ Đức (>10km)', 10.8500, 106.7720),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.s12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _inputDecoration(hint: 'Vĩ độ (Lat)'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: TextFormField(
                            controller: _lngController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _inputDecoration(hint: 'Kinh độ (Lng)'),
                          ),
                        ),
                      ],
                    ),

                    if (distance != null) ...[
                      const SizedBox(height: AppSpacing.s12),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.s12),
                        decoration: BoxDecoration(
                          color:
                              distance <= RestaurantConfig.maxDeliveryDistanceKm
                              ? AppColors.primarySoft
                              : AppColors.errorSoft,
                          borderRadius: AppRadii.radiusMedium,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              distance <= RestaurantConfig.maxDeliveryDistanceKm
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color:
                                  distance <=
                                      RestaurantConfig.maxDeliveryDistanceKm
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
                                      color:
                                          distance <=
                                              RestaurantConfig
                                                  .maxDeliveryDistanceKm
                                          ? AppColors.primaryEnd
                                          : AppColors.error,
                                    ),
                                  ),
                                  Text(
                                    distance <=
                                            RestaurantConfig
                                                .maxDeliveryDistanceKm
                                        ? 'Phí giao dự kiến: ${CurrencyFormatter.formatVND(deliveryFee ?? 0)}'
                                        : 'Vượt quá bán kính 8km! Không thể giao hàng đến vị trí này.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color:
                                          distance <=
                                              RestaurantConfig
                                                  .maxDeliveryDistanceKm
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

  Widget _presetChip(String label, double lat, double lng) {
    return ActionChip(
      label: Text(label),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.radiusSmall,
        side: BorderSide(color: AppColors.border),
      ),
      labelStyle: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 12,
        color: AppColors.textPrimary,
      ),
      onPressed: () => _applyPresetLocation(label, lat, lng),
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
