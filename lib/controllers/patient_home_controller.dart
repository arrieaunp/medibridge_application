import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';

class PatientHomeController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('User').doc(user.uid).get();
        if (userDoc.exists) {
          return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
    return null;
  }

  Future<Map<String, String>?> getUpcomingAppointment() async {
    try {
      DateTime today = DateTime.now();
      DateTime todayWithoutTime =
          DateTime(today.year, today.month, today.day); 

      QuerySnapshot snapshot = await _firestore
          .collection('Appointments')
          .where('patient_id',
              isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('status', whereIn: ['รอชำระเงิน', 'ยืนยันแล้ว'])
          .orderBy('appointment_date')
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime appointmentDate =
            (data['appointment_date'] as Timestamp).toDate();
        DateTime appointmentWithoutTime = DateTime(
            appointmentDate.year, appointmentDate.month, appointmentDate.day);

        if (appointmentWithoutTime.isAfter(todayWithoutTime) ||
            appointmentWithoutTime.isAtSameMomentAs(todayWithoutTime)) {
          QuerySnapshot doctorSnapshot = await _firestore
              .collection('Doctors')
              .where('doctor_id', isEqualTo: data['doctor_id'])
              .limit(1)
              .get();

          if (doctorSnapshot.docs.isNotEmpty) {
            String userId = doctorSnapshot.docs.first['user_id'];
            DocumentSnapshot userSnapshot =
                await _firestore.collection('User').doc(userId).get();

            if (userSnapshot.exists) {
              Map<String, dynamic> userData =
                  userSnapshot.data() as Map<String, dynamic>;
              String doctorName =
                  '${userData['first_name']} ${userData['last_name']}';

              return {
                'date':
                    DateFormat('dd MMMM yyyy', 'th').format(appointmentDate),
                'time': data['appointment_time'],
                'doctor': doctorName,
              };
            }
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching upcoming appointment: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getTopRatedDoctors() async {
    try {
      final querySnapshot = await _firestore.collection('Doctors').get();
      List<Map<String, dynamic>> allDoctors = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> doctorData = doc.data();
        doctorData['id'] = doc.id;

        // ดึงข้อมูลจาก User collection
        String userId = doctorData['user_id'] ?? '';
        if (userId.isNotEmpty) {
          final userDoc = await _firestore.collection('User').doc(userId).get();
          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

            // คำนวณค่าเฉลี่ย rating (หรือให้เป็น 0.0 ถ้าไม่มี feedbacks)
            double rating = _calculateRating(doctorData);

            allDoctors.add({
              'id': doctorData['id'],
              'name': '${userData['first_name']} ${userData['last_name']}',
              'specialization': doctorData['specialization'] ?? 'Unknown',
              'profile_pic': userData['profile_pic'] ?? '',
              'rating': rating, // ใช้ rating จริง หรือ 0.0 ถ้าไม่มีรีวิว
            });
          }
        }
      }

      // ถ้ามีแพทย์ที่มี rating → เรียงจากมากไปน้อย
      List<Map<String, dynamic>> doctorsWithRating =
          allDoctors.where((doctor) => doctor['rating'] > 0).toList();
      doctorsWithRating.sort((a, b) => b['rating'].compareTo(a['rating']));

      // ถ้ามีแพทย์ที่ยังไม่มี rating → สุ่มเลือกแพทย์มาแสดง
      List<Map<String, dynamic>> doctorsWithoutRating =
          allDoctors.where((doctor) => doctor['rating'] == 0.0).toList();
      doctorsWithoutRating.shuffle(); // สุ่มแพทย์ที่ไม่มี rating

      // รวมผลลัพธ์: เอาแพทย์ที่มี rating มาก่อน ตามด้วยแพทย์ที่ไม่มี rating แบบสุ่ม
      List<Map<String, dynamic>> finalDoctors =
          doctorsWithRating.take(2).toList() +
              doctorsWithoutRating.take(2).toList();

      debugPrint('✅ รายชื่อแพทย์ที่จะแสดง: $finalDoctors');
      return finalDoctors;
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการดึงข้อมูลแพทย์: $e');
      return [];
    }
  }

  // ฟังก์ชันคำนวณค่าเฉลี่ย rating (หรือให้เป็น 0.0 ถ้าไม่มี feedbacks)
  double _calculateRating(Map<String, dynamic> doctorData) {
    if (doctorData.containsKey('feedbacks') && doctorData['feedbacks'] is Map) {
      Map<String, dynamic> feedbacks = doctorData['feedbacks'];
      if (feedbacks.isNotEmpty) {
        double totalRating = 0;
        int ratingCount = 0;

        for (var feedback in feedbacks.values) {
          double rating = (feedback['rating'] as num?)?.toDouble() ?? 0;
          totalRating += rating;
          ratingCount++;
        }

        return ratingCount > 0 ? totalRating / ratingCount : 0.0;
      }
    }
    return 0.0; // ถ้าไม่มี feedbacks ให้ rating = 0.0
  }

}
