import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatientHistoryController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> fetchPatientData(String patientId) async {
    try {
      final patientDoc =
          await _firestore.collection('Patients').doc(patientId).get();

      if (!patientDoc.exists) {
        throw Exception('ไม่พบข้อมูลผู้ป่วย');
      }

      final userDoc = await _firestore
          .collection('User')
          .doc(patientDoc['user_id'] ?? '')
          .get();

      if (!userDoc.exists) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }

      return {
        'name':
            '${userDoc['first_name'] ?? 'ไม่ระบุ'} ${userDoc['last_name'] ?? ''}',
        'date_of_birth': patientDoc['date_of_birth'] ?? 'ไม่ระบุ',
        'gender': patientDoc['gender'] ?? 'ไม่ระบุ',
        'blood_type': patientDoc['blood_type'] ?? 'ไม่ระบุ',
        'allergies': patientDoc['allergies'] ?? 'ไม่มี',
        'chronic_conditions': patientDoc['chronic_conditions'] ?? 'ไม่มี',
        'weight': patientDoc['weight']?.toString() ?? 'ไม่ระบุ',
        'height': patientDoc['height']?.toString() ?? 'ไม่ระบุ',
      };
    } catch (e) {
      debugPrint('Error fetching patient data: $e');
      throw Exception('เกิดข้อผิดพลาดในการโหลดข้อมูล');
    }
  }

  String calculateAgeWithDate(String dateString) {
    try {
      // ✅ เพิ่มการรองรับรูปแบบวันที่ เช่น "16 January 2003"
      DateTime birthDate = parseDate(dateString);
      int age = calculateAge(birthDate);
      return '$dateString ($age ปี)';
    } catch (e) {
      return 'ไม่ระบุ';
    }
  }

// 🆕 เพิ่มฟังก์ชัน parseDate() สำหรับการแปลงวันเกิด
  DateTime parseDate(String dateString) {
    try {
      // ลองแปลงโดยใช้ DateFormat สำหรับรูปแบบ "16 January 2003"
      return DateFormat('d MMMM yyyy', 'en_US').parse(dateString);
    } catch (e) {
      // หากแปลงไม่ได้ ลองใช้ DateTime.tryParse สำหรับ ISO8601
      return DateTime.tryParse(dateString) ?? DateTime.now();
    }
  }

  // ฟังก์ชันคำนวณอายุ
  int calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<List<Map<String, dynamic>>> fetchAppointmentHistory(
      String patientId) async {
    List<Map<String, dynamic>> appointments = [];

    // กำหนดวันนี้แบบไม่รวมเวลา (เทียบเฉพาะวันที่)
    DateTime today = DateTime.now();
    DateTime todayOnly = DateTime(today.year, today.month, today.day);

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Appointments')
        .where('patient_id', isEqualTo: patientId)
        .where('appointment_date',
            isLessThan: Timestamp.fromDate(todayOnly)) // กรองเฉพาะอดีต
        .orderBy('appointment_date', descending: true)
        .get();

    for (var doc in querySnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;

      // ดึงข้อมูลหมอจาก Doctors และ Users
      String doctorId = data['doctor_id'] ?? '';
      DocumentSnapshot doctorDoc = await FirebaseFirestore.instance
          .collection('Doctors')
          .doc(doctorId)
          .get();

      String userId = doctorDoc['user_id'] ?? '';
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('User').doc(userId).get();

      // ดึงข้อมูลจาก MedicalRecords
      DocumentSnapshot medicalRecordDoc = await FirebaseFirestore.instance
          .collection('MedicalRecords')
          .doc(data['appointment_id']) // ใช้ appointment_id เป็น reference
          .get();

      // เก็บข้อมูลจาก MedicalRecords
      Map<String, dynamic>? medicalData = medicalRecordDoc.exists
          ? medicalRecordDoc.data() as Map<String, dynamic>?
          : null;

      // รวมข้อมูลหมอ + ประวัติการรักษา
      appointments.add({
        'appointment_date': data['appointment_date'].toDate(),
        'doctor_name':
            '${userDoc['first_name'] ?? ''} ${userDoc['last_name'] ?? ''}',
        'profile_pic': userDoc['profile_pic'] ?? '',
        'diagnosis': medicalData?['diagnosis'] ?? 'ไม่มีข้อมูล',
        'treatment': medicalData?['treatment'] ?? 'ไม่มีข้อมูล',
        'prescription': (medicalData?['prescription'] as List<dynamic>?)
                ?.map((item) => item['frequency'] ?? '')
                .join(", ") ??
            'ไม่มีข้อมูล',
      });
    }

    return appointments;
  }
}
