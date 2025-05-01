import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DoctorHomeController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //ดึงรายชื่อแพทย์
  Future<String> fetchDoctorName(String doctorId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('User').doc(doctorId).get();

      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          return '${data['first_name'] ?? 'ไม่ทราบ'} ${data['last_name'] ?? 'ชื่อ'}';
        }
      }
      return 'ไม่ทราบชื่อ';
    } catch (e) {
      debugPrint('Error fetching doctor name: $e');
      return 'Error';
    }
  }

  //ดึงรายชื่อผู้ป่วย
  Future<String> fetchPatientName(String patientId) async {
    try {
      DocumentSnapshot patientDoc =
          await _firestore.collection('Patients').doc(patientId).get();
      if (patientDoc.exists) {
        Map<String, dynamic> patientData =
            patientDoc.data() as Map<String, dynamic>;
        return '${patientData['first_name']} ${patientData['last_name']}';
      }
    } catch (e) {
      debugPrint('Error fetching patient name: $e');
    }
    return 'Unknown Patient';
  }

  Future<Map<String, dynamic>?> fetchUpcomingAppointment(
      String doctorId) async {
    try {
      QuerySnapshot appointmentsSnapshot = await _firestore
          .collection('Appointments')
          .where('doctor_id', isEqualTo: doctorId)
          .where('status', whereIn: ['รอชำระเงิน', 'ยืนยันแล้ว'])
          .where('appointment_date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime.now())) // ✅ ตรวจสอบให้แน่ใจว่าเป็น Timestamp
          .orderBy('appointment_date',
              descending: false) // ✅ ต้องเรียงจากวันที่ใกล้ที่สุด
          .limit(1)
          .get();

      if (appointmentsSnapshot.docs.isEmpty) {
        return null; // ไม่มีนัดหมาย
      }

      DocumentSnapshot nearestAppointment = appointmentsSnapshot.docs.first;
      Map<String, dynamic>? appointmentData =
          nearestAppointment.data() as Map<String, dynamic>?;

      if (appointmentData == null) return null;

      // ตรวจสอบประเภทของ appointment_date
      dynamic appointmentDate = appointmentData['appointment_date'];
      if (appointmentDate is String) {
        appointmentDate = DateTime.parse(appointmentDate);
      } else if (appointmentDate is Timestamp) {
        appointmentDate = appointmentDate.toDate();
      }

      String patientId = appointmentData['patient_id'] ?? '';
      if (patientId.isEmpty) return null;

      DocumentSnapshot patientSnapshot =
          await _firestore.collection('Patients').doc(patientId).get();
      if (!patientSnapshot.exists) return null;

      String userId = patientSnapshot['user_id'] ?? '';
      if (userId.isEmpty) return null;

      DocumentSnapshot userSnapshot =
          await _firestore.collection('User').doc(userId).get();
      if (!userSnapshot.exists) return null;

      String patientName =
          '${userSnapshot['first_name'] ?? ''} ${userSnapshot['last_name'] ?? ''}';

      return {
        'patient_id': patientId,
        'appointment_date': appointmentDate,
        'appointment_time': appointmentData['appointment_time'] ?? 'ไม่ทราบ',
        'status': appointmentData['status'] ?? 'ไม่ทราบ',
        'patient_name': patientName,
      };
    } catch (e) {
      debugPrint('Error fetching appointment: $e');
      return null;
    }
  }
}
