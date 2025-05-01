import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateUserProfile(String userId, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('User').doc(userId).update(userData);
    } catch (e) {
      throw Exception('Error updating user profile: $e');
    }
  }

  Future<void> updateDoctorData(String doctorId, Map<String, dynamic> doctorData) async {
    try {
      await _firestore.collection('Doctors').doc(doctorId).update(doctorData);
    } catch (e) {
      throw Exception('Error updating doctor data: $e');
    }
  }

  Future<String?> getDoctorIdByUserId(String userId) async {
    try {
      final doctorQuery = await _firestore
          .collection('Doctors')
          .where('user_id', isEqualTo: userId)
          .get();

      if (doctorQuery.docs.isNotEmpty) {
        return doctorQuery.docs.first.id;
      }
      return null; // ถ้าไม่พบ doctorId
    } catch (e) {
      throw Exception('Error fetching doctorId: $e');
    }
  }

  Future<void> saveProfile(String userId, Map<String, dynamic> userData, Map<String, dynamic> doctorData) async {
    try {
      final doctorId = await getDoctorIdByUserId(userId);

      if (doctorId == null) {
        throw Exception('Doctor not found for userId: $userId');
      }

      await updateUserProfile(userId, userData);
      await updateDoctorData(doctorId, doctorData);
    } catch (e) {
      throw Exception('Error saving profile: $e');
    }
  }
}
