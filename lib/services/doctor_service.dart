import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:medibridge_application/models/doctor_model.dart';

class DoctorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ค้นหาแพทย์ด้วยชื่อหรือนามสกุล
  // CHANGED: เพิ่มพารามิเตอร์ selectedDate เพื่อเช็คตารางเวรของวันนั้น
  Future<List<Map<String, dynamic>>> searchByPartialName(
    String partialName,
    DateTime selectedDate, // ADDED
  ) async {
    List<Map<String, dynamic>> results = [];
    debugPrint('Searching for partial name: $partialName'); // Debug log

    // ค้นหาจาก first_name
    QuerySnapshot firstNameSnapshot = await _firestore
        .collection('User')
        .orderBy('first_name')
        .startAt([partialName]).endAt(['$partialName\uf8ff']).get();

    // ค้นหาจาก last_name
    QuerySnapshot lastNameSnapshot = await _firestore
        .collection('User')
        .orderBy('last_name')
        .startAt([partialName]).endAt(['$partialName\uf8ff']).get();

    // รวมเอกสารที่ได้
    List<QueryDocumentSnapshot> allDocs = [
      ...firstNameSnapshot.docs,
      ...lastNameSnapshot.docs,
    ];

    // ตัด doc ที่ซ้ำกันออก
    final uniqueDocs = {for (var doc in allDocs) doc.id: doc}.values;

    // วนลูป userDoc แต่ละตัว
    for (var userDoc in uniqueDocs) {
      final userId = userDoc['user_id'];

      // เช็คว่า userId นี้เป็น doctor หรือไม่
      QuerySnapshot doctorSnapshot = await _firestore
          .collection('Doctors')
          .where('user_id', isEqualTo: userId)
          .get();

      for (var doctorDoc in doctorSnapshot.docs) {
        final doctorData = doctorDoc.data() as Map<String, dynamic>;
        final doctorId = doctorData['doctor_id'];

        // ADDED: ลองเช็คตารางเวรของวันที่ selectedDate
        QuerySnapshot scheduleSnapshot = await _firestore
            .collection('DoctorSchedules')
            .where('doctor_id', isEqualTo: doctorId)
            .where('date', isEqualTo: selectedDate.toIso8601String())
            .get();

        String? startTime;
        String? endTime;

        if (scheduleSnapshot.docs.isNotEmpty) {
          // มีตารางเวรพิเศษในวันนั้น
          var scheduleData =
              scheduleSnapshot.docs.first.data() as Map<String, dynamic>;
          startTime = scheduleData['start_time'];
          endTime = scheduleData['end_time'];
        } else {
          // fallback -> ใช้ default hours ใน Doctors
          startTime = doctorData['available_hours']['start'];
          endTime = doctorData['available_hours']['end'];
        }

        results.add({
          'doctorName': '${userDoc['first_name']} ${userDoc['last_name']}',
          'doctorId': doctorData['doctor_id'], // เดิม
          'scheduleId': doctorDoc.id, // เดิม
          'specialization': doctorData['specialization'],
          // CHANGED: ส่งค่า start_time / end_time กลับด้วย
          'start_time': startTime,
          'end_time': endTime,
        });
      }
    }
    return results;
  }

  Future<Map<String, String?>> getScheduleForDate(
      String doctorId, DateTime date) async {
    try {
      debugPrint("Fetching schedule for doctorId: $doctorId, date: $date");

      QuerySnapshot scheduleSnapshot = await _firestore
          .collection('DoctorSchedules')
          .where('doctor_id', isEqualTo: doctorId)
          .where('date', isEqualTo: date.toIso8601String())
          .get();

      debugPrint("DoctorSchedules found: ${scheduleSnapshot.docs.length}");

      if (scheduleSnapshot.docs.isNotEmpty) {
        var scheduleData =
            scheduleSnapshot.docs.first.data() as Map<String, dynamic>;
        debugPrint("Schedule data: $scheduleData");
        return {
          "start_time": scheduleData['start_time'],
          "end_time": scheduleData['end_time'],
          "default_start_time": null,
          "default_end_time": null,
        };
      } else {
        DocumentSnapshot doctorSnapshot =
            await _firestore.collection('Doctors').doc(doctorId).get();

        debugPrint("Doctors data exists: ${doctorSnapshot.exists}");
        if (doctorSnapshot.exists) {
          var doctorData = doctorSnapshot.data() as Map<String, dynamic>;
          debugPrint(
              "Default available_hours: ${doctorData['available_hours']}");
          return {
            "start_time": null,
            "end_time": null,
            "default_start_time": doctorData['available_hours']['start'],
            "default_end_time": doctorData['available_hours']['end'],
          };
        }
      }
    } catch (e) {
      debugPrint("Error fetching schedule: $e");
    }

    return {
      "start_time": null,
      "end_time": null,
      "default_start_time": '',
      "default_end_time": '',
    };
  }

  Future<void> saveCustomSchedule({
    required String doctorId,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('DoctorSchedules')
          .where('doctor_id', isEqualTo: doctorId)
          .where('date', isEqualTo: date.toIso8601String())
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'start_time': startTime,
          'end_time': endTime,
        });
      } else {
        await _firestore.collection('DoctorSchedules').add({
          'doctor_id': doctorId,
          'date': date.toIso8601String(),
          'start_time': startTime,
          'end_time': endTime,
        });
      }
    } catch (e) {
      debugPrint('Error saving custom schedule: $e');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getDoctorSchedulesWithUserName(
      DateTime date, String dayOfWeek) async {
    List<Map<String, dynamic>> results = [];

    try {
      debugPrint("Fetching doctors for dayOfWeek: $dayOfWeek and date: $date");

      QuerySnapshot doctorSnapshot = await _firestore
          .collection('Doctors')
          .where('available_days', arrayContains: dayOfWeek)
          .get();

      debugPrint(
          "Doctors snapshot: ${doctorSnapshot.docs.length} documents found");

      for (var doctorDoc in doctorSnapshot.docs) {
        final doctorData = doctorDoc.data() as Map<String, dynamic>;
        final doctorId = doctorData['doctor_id'];
        final userId = doctorData['user_id'];

        if (doctorId == null || doctorId.isEmpty) {
          debugPrint("Skipping doctorDoc due to empty doctorId");
          continue;
        }

        // ดึงข้อมูล User
        DocumentSnapshot userDoc =
            await _firestore.collection('User').doc(userId).get();
        debugPrint("User data: ${userDoc.data()}");

        // ดึงข้อมูลตารางเวร
        QuerySnapshot scheduleSnapshot = await _firestore
            .collection('DoctorSchedules')
            .where('doctor_id', isEqualTo: doctorId)
            .where('date', isEqualTo: date.toIso8601String())
            .get();

        if (scheduleSnapshot.docs.isNotEmpty) {
          var scheduleData =
              scheduleSnapshot.docs.first.data() as Map<String, dynamic>;
          debugPrint("Schedule data: $scheduleData");

          results.add({
            'doctorName': '${userDoc['first_name']} ${userDoc['last_name']}',
            'specialization': doctorData['specialization'],
            'scheduleId': scheduleSnapshot.docs.first.id,
            'doctorId': doctorId, // ตรวจสอบว่ามีค่าแน่นอน
            'start_time': scheduleData['start_time'],
            'end_time': scheduleData['end_time'],
          });
        } else {
          debugPrint(
              "No schedule found for doctorId: $doctorId. Using default hours.");
          results.add({
            'doctorName': '${userDoc['first_name']} ${userDoc['last_name']}',
            'specialization': doctorData['specialization'],
            'scheduleId': null,
            'doctorId': doctorId ?? 'unknown', // ตั้งค่า fallback
            'start_time': doctorData['available_hours']['start'],
            'end_time': doctorData['available_hours']['end'],
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching doctor schedules: $e');
    }

    return results;
  }

  Future<DoctorModel?> getDoctorById(String doctorId) async {
    try {
      final docSnapshot =
          await _firestore.collection('Doctors').doc(doctorId).get();
      if (docSnapshot.exists) {
        return DoctorModel.fromFirestore(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching doctor by ID: $e');
    }
  }

  Future<void> updateDoctorById(
      String doctorId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('Doctors').doc(doctorId).update(data);
    } catch (e) {
      throw Exception('Error updating doctor: $e');
    }
  }

  Future<String?> fetchDoctorId(String userId) async {
    final query = await FirebaseFirestore.instance
        .collection('Doctors')
        .where('user_id', isEqualTo: userId)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id; // หรือ query.docs.first['doctor_id']
    }
    return null; // หากไม่พบ doc_id
  }
}
