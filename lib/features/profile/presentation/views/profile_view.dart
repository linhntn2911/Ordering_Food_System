import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ordering_food_system/app/router.dart';
import 'package:ordering_food_system/core/theme/app_colors.dart';
import 'package:ordering_food_system/core/theme/app_radii.dart';
import 'package:ordering_food_system/core/theme/app_spacing.dart';
import 'package:ordering_food_system/core/theme/app_text_styles.dart';
import 'package:ordering_food_system/core/widgets/app_back_button.dart';
import 'package:ordering_food_system/core/widgets/custom_text_field.dart';
import 'package:ordering_food_system/core/widgets/food_ninja_background.dart';
import 'package:ordering_food_system/core/widgets/primary_button.dart';
import 'package:ordering_food_system/core/widgets/sign_in_required_view.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/auth_providers.dart';
import 'package:ordering_food_system/features/profile/presentation/viewmodels/profile_view_model.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  void _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
    String currentPhone,
  ) {
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          padding: EdgeInsets.only(
            top: AppSpacing.p24,
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            bottom:
                MediaQuery.of(modalContext).viewInsets.bottom + AppSpacing.p24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLarge),
            ),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Edit Profile', style: AppTextStyles.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(modalContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.p16),
                CustomTextField(
                  controller: nameController,
                  labelText: 'Full Name',
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: AppColors.primarySolid,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Full name cannot be empty.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.p16),
                CustomTextField(
                  controller: phoneController,
                  labelText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.primarySolid,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Phone number cannot be empty.';
                    }
                    final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9,10}$');
                    if (!phoneRegex.hasMatch(val.trim())) {
                      return 'Please enter a valid 10-digit phone number.';
                    }
                    return null;
                  },
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final state = ref.watch(profileViewModelProvider);
                    if (state.errorMessage == null) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.p12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.p8),
                        decoration: BoxDecoration(
                          color: AppColors.errorSoft,
                          borderRadius: AppSpacing.roundedSmall,
                          border: Border.all(color: AppColors.error, width: 1),
                        ),
                        child: Text(
                          state.errorMessage!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.p24),
                Consumer(
                  builder: (context, ref, _) {
                    final state = ref.watch(profileViewModelProvider);
                    return PrimaryButton(
                      text: 'Save Changes',
                      isLoading: state.isUpdating,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final success = await ref
                            .read(profileViewModelProvider.notifier)
                            .updateProfile(
                              fullName: nameController.text,
                              phone: phoneController.text,
                            );
                        if (success && modalContext.mounted) {
                          Navigator.of(modalContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.surface,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.dialog),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.p24,
              AppSpacing.p32,
              AppSpacing.p24,
              AppSpacing.p24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Food Ninja soft error icon container
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.p20),
                const Text(
                  'Sign Out',
                  style: AppTextStyles.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.p8),
                Text(
                  'Are you sure you want to sign out of your account?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.p24),
                // 2 balanced side-by-side buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadii.card),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadii.card),
                            onTap: () => Navigator.of(dialogContext).pop(),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.p12),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadii.card),
                            onTap: () async {
                              Navigator.of(dialogContext).pop();
                              await ref
                                  .read(profileViewModelProvider.notifier)
                                  .signOut();
                              if (context.mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  AppRoutes.home,
                                  (route) => false,
                                );
                              }
                            },
                            child: Center(
                              child: Text(
                                'Sign Out',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarImage(String? avatarUrl, String fullName) {
    final initial = fullName.trim().isNotEmpty
        ? fullName.trim()[0].toUpperCase()
        : 'U';

    final fallback = Center(
      child: Text(
        initial,
        style: AppTextStyles.displayLarge.copyWith(
          color: Colors.white,
          fontSize: 44,
        ),
      ),
    );

    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return fallback;
    }

    final trimmedUrl = avatarUrl.trim();

    if (trimmedUrl.startsWith('data:image')) {
      try {
        final commaIndex = trimmedUrl.indexOf(',');
        final base64Data = commaIndex != -1
            ? trimmedUrl.substring(commaIndex + 1)
            : trimmedUrl;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          width: 110,
          height: 110,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    }

    if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) {
      return Image.network(
        trimmedUrl,
        width: 110,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    return fallback;
  }

  Future<void> _pickAndUploadAvatar(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.p16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Profile Photo',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.p16),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primarySolid,
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: AppTextStyles.bodyMedium,
                ),
                onTap: () => Navigator.of(modalCtx).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primarySolid,
                ),
                title: const Text(
                  'Take a Photo',
                  style: AppTextStyles.bodyMedium,
                ),
                onTap: () => Navigator.of(modalCtx).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 80,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final success = await ref
        .read(profileViewModelProvider.notifier)
        .uploadAvatar(imageBytes: bytes, imageName: image.name);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload profile picture.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileViewModelProvider);
    final user = state.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FoodNinjaBackground(
        child: SafeArea(
          child: state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primarySolid,
                  ),
                )
              : user == null
              ? SignInRequiredView(
                  onLoginClosed: () {
                    ref.invalidate(profileViewModelProvider);
                    ref.invalidate(authStateProvider);
                  },
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.p16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // The "Tài khoản" tab has nothing to go back to.
                          if (Navigator.of(context).canPop())
                            const AppBackButton()
                          else
                            const SizedBox(width: 45),
                          const Text(
                            'Profile',
                            style: AppTextStyles.headlineMedium,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_note_rounded,
                              color: AppColors.primarySolid,
                              size: 30,
                            ),
                            onPressed: () => _showEditProfileDialog(
                              context,
                              ref,
                              user.fullName,
                              user.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.p24),

                      // Frame 1.43 Profile Avatar Header
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _pickAndUploadAvatar(context, ref),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryEnd
                                              .withValues(alpha: 0.25),
                                          blurRadius: 25,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: _buildAvatarImage(
                                        user.avatarUrl,
                                        user.fullName,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primarySolid,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_outlined,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  if (state.isUpdating)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black38,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.p16),
                            Text(
                              user.fullName.trim().isNotEmpty
                                  ? user.fullName
                                  : 'Anam Wusono',
                              style: AppTextStyles.titleLarge.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.p4),
                            Text(
                              user.email,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p20),

                      // Food Ninja Member Gold / Role Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.p20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppSpacing.roundedCard,
                          boxShadow: AppSpacing.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: user.isAdmin
                                    ? AppColors.warningSurface
                                    : AppColors.primarySoft,
                                borderRadius: AppSpacing.roundedMedium,
                              ),
                              child: Icon(
                                user.isAdmin
                                    ? Icons.admin_panel_settings_rounded
                                    : Icons.stars_rounded,
                                color: user.isAdmin
                                    ? AppColors.foodAccentDark
                                    : AppColors.primarySolid,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.p16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.isAdmin
                                        ? 'Administrator'
                                        : 'Member Gold',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    user.isAdmin
                                        ? 'Full System Authority'
                                        : 'Ngô Chicken Customer',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.successSoft,
                                borderRadius: AppSpacing.roundedPill,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Active',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p20),

                      // Personal Details Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.p20),
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppSpacing.roundedCard,
                          boxShadow: AppSpacing.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personal Info',
                              style: AppTextStyles.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.p16),
                            _ProfileDetailRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Full Name',
                              value: user.fullName,
                            ),
                            const Divider(
                              height: AppSpacing.p24,
                              color: AppColors.borderLight,
                            ),
                            _ProfileDetailRow(
                              icon: Icons.mail_outline_rounded,
                              label: 'Email',
                              value: user.email,
                            ),
                            const Divider(
                              height: AppSpacing.p24,
                              color: AppColors.borderLight,
                            ),
                            _ProfileDetailRow(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: user.phone.isNotEmpty
                                  ? user.phone
                                  : 'Not provided',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p24),
                      const SizedBox(height: AppSpacing.p20),

                      // Activity Card (Notifications & Reviews)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.p20),
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppSpacing.roundedCard,
                          boxShadow: AppSpacing.cardShadow,
                        ),
                        // Transparent Material so ListTile ink shows above
                        // the card's background instead of behind it.
                        child: Material(
                          type: MaterialType.transparency,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Activity & Updates',
                                style: AppTextStyles.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.p12),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primarySoft,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.notifications_outlined,
                                    color: AppColors.primarySolid,
                                    size: 20,
                                  ),
                                ),
                                title: const Text(
                                  'Notifications',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                                onTap: () =>
                                    Navigator.of(context)
                                        .pushNamed(AppRoutes.notifications),
                              ),
                              const Divider(
                                height: 1,
                                color: AppColors.borderLight,
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: AppColors.warningSurface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.rate_review_outlined,
                                    color: AppColors.foodAccentDark,
                                    size: 20,
                                  ),
                                ),
                                title: const Text(
                                  'My Reviews',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                                onTap: () =>
                                    Navigator.of(context)
                                        .pushNamed(AppRoutes.myReviews),
                              ),
                              const Divider(
                                height: 1,
                                color: AppColors.borderLight,
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primarySoft,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.location_on_outlined,
                                    color: AppColors.primarySolid,
                                    size: 20,
                                  ),
                                ),
                                title: const Text(
                                  'Delivery Addresses',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                                onTap: () =>
                                    Navigator.of(context)
                                        .pushNamed(AppRoutes.addresses),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p24),
                      if (user.isAdmin) ...[
                        Container(
                          width: double.infinity,
                          height: 54,
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: AppSpacing.roundedInput,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  AppRoutes.adminDashboard,
                                  (route) => false,
                                );
                              },
                              borderRadius: AppSpacing.roundedInput,
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.dashboard_customize_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.p8),
                                    Text(
                                      'Admin Dashboard',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.p16),
                      ],

                      // Sign Out Button (Food Ninja Soft Error Card)
                      Container(
                        width: double.infinity,
                        height: 54,
                        decoration: const BoxDecoration(
                          color: AppColors.errorSoft,
                          borderRadius: AppSpacing.roundedInput,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _confirmSignOut(context, ref),
                            borderRadius: AppSpacing.roundedInput,
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.logout_rounded,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.p8),
                                  Text(
                                    'Sign Out',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: AppSpacing.roundedSmall,
          ),
          child: Icon(icon, color: AppColors.primarySolid, size: 20),
        ),
        const SizedBox(width: AppSpacing.p12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
