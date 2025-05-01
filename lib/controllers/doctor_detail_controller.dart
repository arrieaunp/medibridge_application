import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DoctorDetailController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> fetchDoctorData(String doctorId) async {
    try {
      DocumentSnapshot doctorSnapshot =
          await _firestore.collection('Doctors').doc(doctorId).get();

      if (!doctorSnapshot.exists) {
        throw Exception("ไม่พบข้อมูลแพทย์");
      }

      var doctorData = doctorSnapshot.data() as Map<String, dynamic>;
      String userId = doctorData['user_id'];

      DocumentSnapshot userSnapshot =
          await _firestore.collection('User').doc(userId).get();

      if (!userSnapshot.exists) {
        throw Exception("ไม่พบข้อมูลผู้ใช้ของแพทย์");
      }

      var userData = userSnapshot.data() as Map<String, dynamic>;

      return {
        ...doctorData,
        ...userData,
        'education': doctorData['education'] ?? 'ไม่มีข้อมูล',
        'available_hours':
            doctorData['available_hours'] ?? {'start': 'N/A', 'end': 'N/A'},
        'available_days': doctorData['available_days'] ?? [],
      };
    } catch (e) {
      debugPrint("🔥 Error fetching doctor data: $e");
      throw Exception("เกิดข้อผิดพลาดในการโหลดข้อมูลแพทย์");
    }
  }

  // 📌 คำนวณคะแนนรีวิวเฉลี่ย
  int calculateAverageRating(Map<String, dynamic>? feedbacks) {
    if (feedbacks == null || feedbacks.isEmpty) return 0;

    double totalRating = 0;
    feedbacks.forEach((key, feedback) {
      totalRating += feedback['rating'] ?? 0;
    });

    return (totalRating / feedbacks.length).round();
  }
}
