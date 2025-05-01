import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role, // 'Patient', 'Doctor', 'Staff'
    required String phoneNumber,
    // ข้อมูลเพิ่มเติมสำหรับผู้ป่วย (Patient)
    String? allergies,
    String? bloodType,
    String? chronicConditions,
    String? dateOfBirth,
    String? emergencyContact,
    String? gender,
    int? height,
    int? weight,
  }) async {
    try {
      // สร้างผู้ใช้งานใหม่ใน Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String userId = userCredential.user!.uid;

      // บันทึกข้อมูลผู้ใช้ลงใน Firestore (Users collection)
      await _firestore.collection('Users').doc(userId).set({
        'user_id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone_number': phoneNumber,
        'role': role,
        'profile_pic': '',
      });

      // ถ้า role เป็น Patient ให้บันทึกข้อมูลเพิ่มเติมลงใน collection 'Patients'
      if (role == 'Patient') {
        String patientId = userId; // สามารถใช้ userId เป็น patientId ได้
        await _firestore.collection('Patients').doc(patientId).set({
          'patient_id': patientId,
          'user_id': userId,
          'allergies': allergies ?? '',
          'blood_type': bloodType ?? '',
          'chronic_conditions': chronicConditions ?? '',
          'date_of_birth': dateOfBirth ?? '',
          'emergency_contact': emergencyContact ?? '',
          'gender': gender ?? '',
          'height': height ?? 0,
          'weight': weight ?? 0,
        });
      }

      // เพิ่มเงื่อนไขสำหรับ role อื่นๆ เช่น Doctor หรือ Staff ตามที่คุณต้องการ

    } catch (e) {
      print("Error adding new user: $e");
      throw Exception('ไม่สามารถเพิ่มผู้ใช้งานใหม่ได้');
    }
  }
}
