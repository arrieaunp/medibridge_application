import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DoctorsListController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchDoctors() async {
    try {
      final querySnapshot = await _firestore.collection('Doctors').get();
      List<Map<String, dynamic>> allDoctors = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> doctorData = doc.data();
        doctorData['id'] = doc.id;

        // ดึงข้อมูล User ตาม user_id
        String userId = doctorData['user_id'] ?? '';
        if (userId.isNotEmpty) {
          final userDoc = await _firestore.collection('User').doc(userId).get();
          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

            allDoctors.add({
              'id': doctorData['id'],
              'name': '${userData['first_name']} ${userData['last_name']}',
              'specialization': doctorData['specialization'] ?? 'Unknown',
              'profile_pic': userData['profile_pic'] ?? '',
            });
          }
        }
      }

      return allDoctors;
    } catch (e) {
      debugPrint('❌ Error fetching doctors: $e');
      return [];
    }
  }
}
