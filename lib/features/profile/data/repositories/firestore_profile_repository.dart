import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ordering_food_system/core/errors/app_exception.dart';
import 'package:ordering_food_system/core/firebase/firestore_paths.dart';
import 'package:ordering_food_system/features/auth/data/models/user_model.dart';
import 'package:ordering_food_system/features/auth/domain/entities/app_user.dart';
import 'package:ordering_food_system/features/profile/domain/repositories/profile_repository.dart';

class FirestoreProfileRepository implements ProfileRepository {
  final FirebaseFirestore _firestore;

  FirestoreProfileRepository(this._firestore);

  @override
  Future<AppUser> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.doc(FirestorePaths.user(uid)).get();
      if (!doc.exists) {
        throw const NotFoundException('User profile not found.');
      }
      return UserModel.fromFirestore(doc).toEntity();
    } on AppException {
      rethrow;
    } catch (e) {
      throw ValidationException(e.toString());
    }
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String phone,
    String? avatarUrl,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (avatarUrl != null) {
        updateData['avatarUrl'] = avatarUrl;
      }

      await _firestore.doc(FirestorePaths.user(uid)).update(updateData);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ValidationException('Failed to update profile: ${e.toString()}');
    }
  }
}
