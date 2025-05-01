import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:medibridge_application/models/medical_record_model.dart';

class MedicalRecordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// ✅ ฟังก์ชันดึงรายชื่อผู้ป่วย
  Future<List<Map<String, dynamic>>> fetchPatientsList(String doctorId) async {
    try {
      // ดึงนัดหมายทั้งหมดของหมอคนนี้ ไม่จำกัดวัน (ทั้งอดีตและอนาคต)
      QuerySnapshot appointmentsSnapshot = await _firestore
          .collection('Appointments')
          .where('doctor_id', isEqualTo: doctorId)
          .get();

      print(
          "🔥 ดึงข้อมูล Appointment ได้: ${appointmentsSnapshot.docs.length} รายการ");

      Set<String> patientIds = {};
      for (var doc in appointmentsSnapshot.docs) {
        String? patientId = doc['patient_id'];
        if (patientId != null && patientId.isNotEmpty) {
          patientIds.add(patientId);
        }
      }

      print("✅ patient_id ที่ไม่ซ้ำกัน: ${patientIds.length} คน");

      List<Map<String, dynamic>> patientsList = [];

      for (String patientId in patientIds) {
        DocumentSnapshot patientSnapshot =
            await _firestore.collection('Patients').doc(patientId).get();

        if (!patientSnapshot.exists) {
          print("⚠️ ไม่พบข้อมูล Patients สำหรับ patient_id: $patientId");
          continue;
        }

        String userId = patientSnapshot['user_id'] ?? '';
        if (userId.isEmpty) {
          print("⚠️ user_id ว่างสำหรับ patient_id: $patientId");
          continue;
        }

        DocumentSnapshot userSnapshot =
            await _firestore.collection('User').doc(userId).get();

        if (!userSnapshot.exists) {
          print("⚠️ ไม่พบข้อมูล User สำหรับ user_id: $userId");
          continue;
        }

        Map<String, dynamic>? userData =
            userSnapshot.data() as Map<String, dynamic>?;
        String firstName = userData?['first_name'] ?? 'ไม่ระบุ';
        String lastName = userData?['last_name'] ?? 'ไม่ระบุ';
        String fullName = "$firstName $lastName";

        Map<String, dynamic>? patientData =
            patientSnapshot.data() as Map<String, dynamic>?;

        DateTime? birthDate;
        int age = 0;
        if (patientData != null && patientData.containsKey('date_of_birth')) {
          try {
            // แปลงรูปแบบ "08 April 2003" เป็น DateTime ด้วย DateFormat
            birthDate =
                DateFormat("dd MMMM yyyy").parse(patientData['date_of_birth']);
            age = DateTime.now().year - birthDate.year;
          } catch (e) {
            print(
                "⚠️ ไม่สามารถแปลง birthdate: ${patientData['date_of_birth']} - Error: $e");
          }
        } else {
          print("⚠️ ไม่พบ birthdate สำหรับ patient_id: $patientId");
        }

        print("🎉 พบผู้ป่วย: $fullName อายุ: $age ปี");

        patientsList.add({
          'patient_id': patientId,
          'full_name': fullName,
          'age': age,
          'gender': patientSnapshot['gender'] ?? 'ไม่ระบุ',
        });
      }

      print("✅ ส่งรายชื่อผู้ป่วยทั้งหมด: ${patientsList.length} คน");
      return patientsList;
    } catch (e) {
      print('❌ Error fetching patients list: $e');
      return [];
    }
  }

  /// ✅ ดึงประวัติการนัดหมายของผู้ป่วย
  Future<List<Map<String, dynamic>>> fetchPatientAppointments(
      String patientId, String doctorId) async {
    try {
      print("Debug: patientId = $patientId, doctorId = $doctorId");
      Query appointmentsQuery = _firestore
          .collection('Appointments')
          .where('patient_id', isEqualTo: patientId)
          .where('doctor_id', isEqualTo: doctorId)
          .where('appointment_date', isLessThan: Timestamp.now())
          .orderBy('appointment_date', descending: true);

      QuerySnapshot appointmentsSnapshot = await appointmentsQuery.get();
      print(
          "Debug: Appointment snapshot count: ${appointmentsSnapshot.docs.length}");

      // ถ้าไม่มีเอกสารใด ๆ แสดง warning
      if (appointmentsSnapshot.docs.isEmpty) {
        print("Warning: ไม่มีข้อมูล Appointment ที่ตรงกับเงื่อนไขที่ให้");
      }

      List<Map<String, dynamic>> appointmentList = [];
      for (var doc in appointmentsSnapshot.docs) {
        Map<String, dynamic> appointmentData =
            doc.data() as Map<String, dynamic>;
        String appointmentId = doc.id;

        // Debug log สำหรับแต่ละ appointment
        print("Debug: Appointment Data: $appointmentData");

        // ดึงข้อมูลจาก MedicalRecords
        QuerySnapshot<Map<String, dynamic>> medicalRecordSnapshot =
            await _firestore
                .collection('MedicalRecords')
                .where('appointment_id', isEqualTo: appointmentId)
                .limit(1)
                .get();

        String diagnosis = "ไม่ระบุ";
        if (medicalRecordSnapshot.docs.isNotEmpty) {
          Map<String, dynamic> medicalData =
              medicalRecordSnapshot.docs.first.data();
          if (medicalData.containsKey('diagnosis')) {
            diagnosis = medicalData['diagnosis'];
          }
        } else {
          print(
              "Debug: ไม่มีข้อมูล MedicalRecords สำหรับ appointment_id: $appointmentId");
        }

        String appointmentDateStr = 'ไม่ระบุ';
        if (appointmentData.containsKey('appointment_date')) {
          try {
            appointmentDateStr = appointmentData['appointment_date']
                .toDate()
                .toString()
                .split(' ')[0];
          } catch (e) {
            print(
                "Error converting appointment_date for appointment_id: $appointmentId - Error: $e");
          }
        } else {
          print(
              "Warning: ไม่มี field appointment_date ใน appointment_id: $appointmentId");
        }

        appointmentList.add({
          'appointment_id': appointmentId,
          'date': appointmentDateStr,
          'diagnosis': diagnosis,
        });
      }

      print("Debug: Returning ${appointmentList.length} appointments");
      return appointmentList;
    } catch (e) {
      print('❌ Error fetching patient appointments: $e');
      return [];
    }
  }

  /// ✅ ดึงข้อมูล Medical Record จาก Firestore
  Future<MedicalRecordModel?> fetchMedicalRecord(String appointmentId) async {
    try {
      QuerySnapshot medicalRecordSnapshot = await _firestore
          .collection('MedicalRecords')
          .where('appointment_id', isEqualTo: appointmentId)
          .limit(1)
          .get();

      if (medicalRecordSnapshot.docs.isEmpty) {
        print("⚠️ ไม่พบ Medical Record สำหรับ appointmentId: $appointmentId");
        return null; // ✅ คืนค่า null ถ้าไม่มีข้อมูล
      }

      return MedicalRecordModel.fromFirestore(medicalRecordSnapshot.docs.first);
    } catch (e) {
      print("❌ Error fetching medical record: $e");
      return null;
    }
  }

  /// ✅ บันทึกหรืออัปเดตข้อมูล Medical Record
  Future<void> updateMedicalRecord(
      String appointmentId, MedicalRecordModel record) async {
    try {
      DocumentReference recordRef =
          _firestore.collection('MedicalRecords').doc(appointmentId);
      await recordRef.set(record.toFirestore(), SetOptions(merge: true));
      print("✅ อัปเดตข้อมูล MedicalRecord สำเร็จ");
    } catch (e) {
      print("❌ Error updating MedicalRecord: $e");
    }
  }

  Future<Map<String, dynamic>> fetchPatientInfo(String patientId) async {
    try {
      DocumentSnapshot patientSnapshot =
          await _firestore.collection('Patients').doc(patientId).get();
      if (!patientSnapshot.exists) {
        throw Exception("❌ ไม่พบข้อมูลผู้ป่วย patientId: $patientId");
      }

      String userId = patientSnapshot['user_id'] ?? '';
      if (userId.isEmpty) {
        throw Exception("❌ user_id ว่างสำหรับ patientId: $patientId");
      }

      DocumentSnapshot userSnapshot =
          await _firestore.collection('User').doc(userId).get();
      if (!userSnapshot.exists) {
        throw Exception("❌ ไม่พบข้อมูลผู้ใช้ user_id: $userId");
      }

      // --- กำหนด age ไว้ก่อนเป็น 0 หรือ null ---
      int age = 0;
      String? dobString =
          patientSnapshot.data().toString().contains('date_of_birth')
              ? patientSnapshot['date_of_birth']
              : null;

      if (dobString != null && dobString.trim().isNotEmpty) {
        // สมมติยังเก็บเป็น string รูปแบบ "08 April 2003"
        // หรือใช้ try-catch ป้องกัน parse error
        try {
          List<String> parts = dobString.split(' ');
          if (parts.length == 3) {
            // เช่น ["08", "April", "2003"]
            int birthYear = int.parse(parts[2]);
            age = DateTime.now().year - birthYear;
          }
        } catch (e) {
          print("⚠️ แปลง date_of_birth ไม่ได้: $dobString => set age = 0");
          age = 0;
        }
      }

      return {
        'full_name':
            '${userSnapshot['first_name']} ${userSnapshot['last_name']}',
        'first_name': '${userSnapshot['first_name']}',
        'last_name': '${userSnapshot['last_name']}',
        'age': age, // ถ้า parse ไม่ได้จะเป็น 0
        'gender': patientSnapshot['gender'] ?? 'ไม่ระบุ',
        'allergies': patientSnapshot['allergies'] ?? 'ไม่มีข้อมูล',
        'chronic_conditions':
            patientSnapshot['chronic_conditions'] ?? 'ไม่มีข้อมูล',
      };
    } catch (e) {
      print("❌ Error fetching patient info: $e");
      return {
        'first_name': '',
        'last_name': '',
        'age': '',
        'gender': '',
        'allergies': '',
        'chronic_conditions': ''
      };
    }
  }

  // ✅ โหลดประวัติการรักษาทั้งหมด
  Future<List<Map<String, dynamic>>> getMedicalHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    String patientId = user.uid;

    QuerySnapshot appointmentsSnapshot = await _firestore
        .collection('Appointments')
        .where('patient_id', isEqualTo: patientId)
        .orderBy('appointment_date', descending: true)
        .get();

    List<Map<String, dynamic>> medicalHistory = [];

    for (var appointmentDoc in appointmentsSnapshot.docs) {
      var appointmentData = appointmentDoc.data() as Map<String, dynamic>;
      String appointmentId = appointmentData['appointment_id'] ?? '';
      String doctorId = appointmentData['doctor_id'] ?? '';

      if (doctorId.isEmpty || appointmentId.isEmpty) {
        print(
            "❌ พบค่าที่ว่าง: appointmentId = $appointmentId, doctorId = $doctorId");
        continue;
      }

      Map<String, String> doctorInfo = await getDoctorInfo(doctorId);
      String doctorName = doctorInfo['name'] ?? 'ไม่พบชื่อแพทย์';
      String doctorProfilePic = doctorInfo['profile_pic'] ?? '';

      DocumentSnapshot medicalRecordDoc = await _firestore
          .collection('MedicalRecords')
          .doc(appointmentId)
          .get();

      if (medicalRecordDoc.exists) {
        var medicalData = medicalRecordDoc.data() as Map<String, dynamic>;

        // ✅ เช็คว่า appointment_date เป็น Timestamp หรือ String
        var appointmentDate = appointmentData['appointment_date'];
        if (appointmentDate is Timestamp) {
          appointmentDate = appointmentDate.toDate();
        }

        medicalHistory.add({
          'appointment_id': appointmentId, // ✅ เพิ่ม appointment_id
          'patient_id': patientId, // ✅ เพิ่ม patient_id
          'doctor_id': doctorId, // ✅ เพิ่ม doctor_id
          'appointment_date': appointmentDate, // ✅ ป้องกันปัญหา Timestamp
          'doctor_name': doctorName,
          'doctor_profile_pic': doctorProfilePic,
          'diagnosis': medicalData['diagnosis'],
          'treatment': medicalData['treatment'],
          'prescription': medicalData['prescription'],
        });
      }
    }

    return medicalHistory;
  }

  // ✅ โหลดประวัติการรักษาเฉพาะวันที่เลือก
  Future<List<Map<String, dynamic>>> getMedicalHistoryByDate(
      DateTime? selectedDate) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    String patientId = user.uid;
    Query query = _firestore
        .collection('Appointments')
        .where('patient_id', isEqualTo: patientId);

    if (selectedDate != null) {
      Timestamp startOfDay = Timestamp.fromDate(DateTime(
          selectedDate.year, selectedDate.month, selectedDate.day, 0, 0, 0));
      Timestamp endOfDay = Timestamp.fromDate(DateTime(
          selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59));

      query = query
          .where('appointment_date', isGreaterThanOrEqualTo: startOfDay)
          .where('appointment_date', isLessThanOrEqualTo: endOfDay);
    } else {
      query = query.orderBy('appointment_date', descending: true).limit(5);
    }

    QuerySnapshot appointmentsSnapshot = await query.get();
    List<Map<String, dynamic>> medicalHistory = [];

    for (var appointmentDoc in appointmentsSnapshot.docs) {
      var appointmentData = appointmentDoc.data() as Map<String, dynamic>;
      String appointmentId = appointmentData['appointment_id'];
      String doctorId = appointmentData['doctor_id'] ?? '';

      if (doctorId.isEmpty) continue;

      Map<String, String> doctorInfo = await getDoctorInfo(doctorId);
      String doctorName = doctorInfo['name'] ?? 'ไม่พบชื่อแพทย์';
      String doctorProfilePic = doctorInfo['profile_pic'] ?? '';

      DocumentSnapshot medicalRecordDoc = await _firestore
          .collection('MedicalRecords')
          .doc(appointmentId)
          .get();

      if (medicalRecordDoc.exists) {
        var medicalData = medicalRecordDoc.data() as Map<String, dynamic>;
        medicalHistory.add({
          'appointment_id': appointmentId,
          'patient_id': patientId,
          'doctor_id': doctorId,
          'appointment_date':
              appointmentData['appointment_date'], // ✅ ยังคงเป็น Timestamp
          'doctor_name': doctorName,
          'doctor_profile_pic': doctorProfilePic,
          'diagnosis': medicalData['diagnosis'],
          'treatment': medicalData['treatment'],
          'prescription': medicalData['prescription'],
        });
      }
    }

    return medicalHistory;
  }

  // ✅ ดึงข้อมูลแพทย์ (ชื่อ + รูปโปรไฟล์)
  Future<Map<String, String>> getDoctorInfo(String doctorId) async {
    DocumentSnapshot doctorDoc =
        await _firestore.collection('Doctors').doc(doctorId).get();

    if (doctorDoc.exists && doctorDoc.data() != null) {
      var doctorData = doctorDoc.data() as Map<String, dynamic>;
      String userId = doctorData['user_id'] ?? '';

      if (userId.isNotEmpty) {
        DocumentSnapshot userDoc =
            await _firestore.collection('User').doc(userId).get();

        if (userDoc.exists && userDoc.data() != null) {
          var userData = userDoc.data() as Map<String, dynamic>;
          return {
            'name': "${userData['first_name']} ${userData['last_name']}",
            'profile_pic': userData['profile_pic'] ?? '',
          };
        }
      }
    }

    return {'name': 'ไม่พบชื่อแพทย์', 'profile_pic': ''};
  }
}
