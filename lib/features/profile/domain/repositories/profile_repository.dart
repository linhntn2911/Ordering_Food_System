import 'package:ordering_food_system/features/auth/domain/entities/app_user.dart';

abstract class ProfileRepository {
  /// Fetches the profile of a given user.
  Future<AppUser> getUserProfile(String uid);

  /// Updates allowed profile fields (fullName, phone, avatarUrl).
  /// Role and status modifications are strictly forbidden.
  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String phone,
    String? avatarUrl,
  });
}
