import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medibridge_application/config.dart';
import 'package:medibridge_application/services/notification_service.dart';
import './../models/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateAppointmentStatus(
      String appointmentId, String newStatus) async {
    try {
      Map<String, dynamic> updateData = {'status': newStatus};

      // ตรวจสอบสถานะที่เปลี่ยนแปลงและอัปเดตข้อมูลเพิ่มเติม
      if (newStatus == 'รอชำระเงิน') {
        updateData.addAll({
          'payment_amount': 0,
          'payment_status': 'รอเพิ่มรายการชำระเงิน',
          'payment_date': null,
        });
      } else if (newStatus == 'ยกเลิก') {
        updateData.addAll({
          'payment_amount': 0,
          'payment_status': 'ยกเลิก',
          'payment_date': null,
        });
      }

      // ✅ อัปเดตสถานะการนัดหมายใน Firestore
      await _firestore
          .collection('Appointments')
          .doc(appointmentId)
          .update(updateData);

      // ✅ ดึงข้อมูลผู้ป่วยจาก Firestore
      DocumentSnapshot appointmentSnapshot =
          await _firestore.collection('Appointments').doc(appointmentId).get();
      String patientId = appointmentSnapshot['patient_id'];

      // ✅ แปลง Timestamp เป็น DateTime ก่อนแปลงเป็น String
      Timestamp appointmentTimestamp = appointmentSnapshot['appointment_date'];
      DateTime appointmentDateTime = appointmentTimestamp.toDate();

      String appointmentDate =
          DateFormat('dd/MM/yyyy').format(appointmentDateTime);

      DocumentSnapshot patientSnapshot =
          await _firestore.collection('User').doc(patientId).get();
      String patientEmail = patientSnapshot['email'];
      String patientName =
          patientSnapshot['first_name'] + ' ' + patientSnapshot['last_name'];

      // ✅ กำหนดข้อความแจ้งเตือนให้เหมาะสมกับสถานะที่เปลี่ยนไป
      String emailSubject = 'แจ้งเตือนการนัดหมายจาก MediBridge';
      String emailBody = '';

      if (newStatus == 'รอชำระเงิน') {
        emailBody = '''
เรียนคุณ $patientName,

ทางโรงพยาบาลขอแจ้งให้ทราบว่า นัดหมายของคุณในวันที่ $appointmentDate ได้รับการยืนยันแล้ว 

กรุณาดำเนินการชำระเงินให้เสร็จสิ้นตามขั้นตอนที่ระบุ เพื่อให้การนัดหมายของคุณสามารถดำเนินไปได้ตามแผนที่กำหนด

หากคุณมีข้อสงสัย หรือต้องการข้อมูลเพิ่มเติม กรุณาติดต่อฝ่ายบริการของโรงพยาบาล

ขอขอบคุณที่ใช้บริการ MediBridge
''';
      } else if (newStatus == 'ยกเลิก') {
        emailBody = '''
เรียนคุณ $patientName,

เราขอแจ้งให้ทราบว่า นัดหมายของคุณในวันที่ $appointmentDate ถูกยกเลิกแล้ว

หากคุณต้องการทำการนัดหมายใหม่ กรุณาติดต่อฝ่ายบริการของโรงพยาบาล หรือทำการนัดหมายใหม่ผ่านระบบ MediBridge 

ขออภัยในความไม่สะดวก และขอขอบคุณที่ใช้บริการ MediBridge
''';
      }

      // ✅ เรียกใช้ฟังก์ชัน `sendEmailNotification()`
      await NotificationService.instance.sendEmailNotification(
        toEmail: patientEmail,
        subject: emailSubject,
        body: emailBody,
      );

      print('✅ อัปเดตสถานะการนัดหมายเรียบร้อย และส่งอีเมลแจ้งเตือนสำเร็จ');
    } catch (e) {
      throw Exception('❌ Error updating appointment status: $e');
    }
  }

  // Query นัดหมายที่มีสถานะ 'รอยืนยัน'
  Future<List<AppointmentModel>> getPendingAppointments() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Appointments')
          .where('status', isEqualTo: 'รอยืนยัน')
          .get();

      return snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching pending appointments: $e');
    }
  }

  // Query นัดหมายที่มีสถานะ 'รอชำระเงิน'
  Future<List<Map<String, dynamic>>>
      getPaymentPendingAppointmentsWithDetails() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Appointments')
          .where('status', isEqualTo: 'รอชำระเงิน')
          .get();

      List<Map<String, dynamic>> result = [];

      for (var doc in snapshot.docs) {
        AppointmentModel appointment = AppointmentModel.fromFirestore(doc);
        String patientId = appointment.patientId;
        String doctorId = appointment.doctorId;

        // ดึงข้อมูลของผู้ป่วย
        QuerySnapshot patientSnapshot = await _firestore
            .collection('Patients')
            .where('patient_id', isEqualTo: patientId)
            .limit(1)
            .get();
        String patientUserId = patientSnapshot.docs.first.get('user_id');

        // ดึงข้อมูลของแพทย์
        QuerySnapshot doctorSnapshot = await _firestore
            .collection('Doctors')
            .where('doctor_id', isEqualTo: doctorId)
            .limit(1)
            .get();
        String doctorUserId = doctorSnapshot.docs.first.get('user_id');

        // ดึงชื่อผู้ป่วยและแพทย์จาก User collection
        DocumentSnapshot patientUserDoc =
            await _firestore.collection('User').doc(patientUserId).get();
        DocumentSnapshot doctorUserDoc =
            await _firestore.collection('User').doc(doctorUserId).get();

        result.add({
          'appointment': appointment,
          'patient_name':
              '${patientUserDoc.get('first_name')} ${patientUserDoc.get('last_name')}',
          'doctor_name':
              '${doctorUserDoc.get('first_name')} ${doctorUserDoc.get('last_name')}',
        });
      }

      return result;
    } catch (e) {
      throw Exception('Error fetching payment pending appointments: $e');
    }
  }

  // ดึงข้อมูลผู้ใช้งานจาก User collection ตาม user_id
  static Future<DocumentSnapshot> getUserById(String userId) async {
    final query = await FirebaseFirestore.instance
        .collection('User')
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .get();
    return query.docs.first;
  }

  Future<DocumentSnapshot> getAppointmentById(String appointmentId) async {
    return await _firestore.collection('Appointments').doc(appointmentId).get();
  }

  Future<String> getUserNameById(String userId) async {
    final querySnapshot = await _firestore
        .collection('User')
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final userData = querySnapshot.docs.first.data();
      return '${userData['first_name']} ${userData['last_name']}';
    } else {
      throw Exception('User not found');
    }
  }

  Future<List<Map<String, dynamic>>> getAppointmentsByStatus(
      String status) async {
    try {
      debugPrint(
          "Fetching appointments with status: '$status'"); // ตรวจสอบค่า status ที่รับเข้ามา

      // Query นัดหมายตามสถานะที่ส่งเข้ามา
      QuerySnapshot snapshot = await _firestore
          .collection('Appointments')
          .where('status', isEqualTo: status.trim()) // ใช้ trim() กันช่องว่าง
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint("No appointments found for status: '$status'");
      }

      List<Map<String, dynamic>> result = [];

      for (var doc in snapshot.docs) {
        debugPrint(
            "Fetched document ID: ${doc.id}, Data: ${doc.data()}"); // เช็คว่าดึงเอกสารอะไรมา

        AppointmentModel appointment = AppointmentModel.fromFirestore(doc);
        String patientId = appointment.patientId;
        String doctorId = appointment.doctorId;

        // ดึงข้อมูลของผู้ป่วย
        QuerySnapshot patientSnapshot = await _firestore
            .collection('Patients')
            .where('patient_id', isEqualTo: patientId)
            .limit(1)
            .get();

        if (patientSnapshot.docs.isEmpty) {
          debugPrint("No patient found for ID: $patientId");
        }

        String patientUserId = patientSnapshot.docs.first.get('user_id');

        // ดึงข้อมูลของแพทย์
        QuerySnapshot doctorSnapshot = await _firestore
            .collection('Doctors')
            .where('doctor_id', isEqualTo: doctorId)
            .limit(1)
            .get();

        if (doctorSnapshot.docs.isEmpty) {
          debugPrint("No doctor found for ID: $doctorId");
        }

        String doctorUserId = doctorSnapshot.docs.first.get('user_id');

        // ดึงชื่อผู้ป่วยและแพทย์จาก User collection
        DocumentSnapshot patientUserDoc =
            await _firestore.collection('User').doc(patientUserId).get();
        DocumentSnapshot doctorUserDoc =
            await _firestore.collection('User').doc(doctorUserId).get();

        debugPrint(
            "Patient Name: ${patientUserDoc.get('first_name')} ${patientUserDoc.get('last_name')}");
        debugPrint(
            "Doctor Name: ${doctorUserDoc.get('first_name')} ${doctorUserDoc.get('last_name')}");

        result.add({
          'appointment_id': doc.id, // ใช้ doc.id แทน appointment_id จากเอกสาร
          'appointment': appointment,
          'patient_id': patientId,
          'doctor_id': doctorId,
          'patient_name': patientUserDoc.get('first_name') != null &&
                  patientUserDoc.get('last_name') != null
              ? '${patientUserDoc.get('first_name')} ${patientUserDoc.get('last_name')}'
              : 'ไม่ทราบชื่อผู้ป่วย',
          'doctor_name': doctorUserDoc.get('first_name') != null &&
                  doctorUserDoc.get('last_name') != null
              ? '${doctorUserDoc.get('first_name')} ${doctorUserDoc.get('last_name')}'
              : 'ไม่ทราบชื่อแพทย์',
          'appointment_date':
              DateFormat('dd/MM/yyyy').format(appointment.appointmentDate),
          'appointment_time': appointment.appointmentTime,
        });
      }

      debugPrint("Total appointments fetched: ${result.length}");
      return result;
    } catch (e) {
      debugPrint("Error fetching appointments by status: $e");
      throw Exception('Error fetching appointments by status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAppointmentsByPaymentStatus(
      String paymentStatus) async {
    try {
      // Query นัดหมายตามสถานะการชำระเงินที่ส่งเข้ามา
      QuerySnapshot snapshot = await _firestore
          .collection('Appointments')
          .where('payment_status', isEqualTo: paymentStatus)
          .get();

      List<Map<String, dynamic>> result = [];

      for (var doc in snapshot.docs) {
        AppointmentModel appointment = AppointmentModel.fromFirestore(doc);
        String patientId = appointment.patientId;
        String doctorId = appointment.doctorId;

        // ดึงข้อมูลของผู้ป่วย
        QuerySnapshot patientSnapshot = await _firestore
            .collection('Patients')
            .where('patient_id', isEqualTo: patientId)
            .limit(1)
            .get();
        String patientUserId = patientSnapshot.docs.first.get('user_id');

        // ดึงข้อมูลของแพทย์
        QuerySnapshot doctorSnapshot = await _firestore
            .collection('Doctors')
            .where('doctor_id', isEqualTo: doctorId)
            .limit(1)
            .get();
        String doctorUserId = doctorSnapshot.docs.first.get('user_id');

        // ดึงชื่อผู้ป่วยและแพทย์จาก User collection
        DocumentSnapshot patientUserDoc =
            await _firestore.collection('User').doc(patientUserId).get();
        DocumentSnapshot doctorUserDoc =
            await _firestore.collection('User').doc(doctorUserId).get();

        result.add({
          'appointment_id': doc.id, // ใช้ doc.id แทน appointment_id จากเอกสาร
          'appointment': appointment,
          'patient_name': patientUserDoc.get('first_name') != null &&
                  patientUserDoc.get('last_name') != null
              ? '${patientUserDoc.get('first_name')} ${patientUserDoc.get('last_name')}'
              : 'ไม่ทราบชื่อผู้ป่วย',
          'doctor_name': doctorUserDoc.get('first_name') != null &&
                  doctorUserDoc.get('last_name') != null
              ? '${doctorUserDoc.get('first_name')} ${doctorUserDoc.get('last_name')}'
              : 'ไม่ทราบชื่อแพทย์',
          'appointment_date':
              DateFormat('dd/MM/yyyy').format(appointment.appointmentDate),
          'appointment_time': appointment.appointmentTime,
        });
      }

      return result;
    } catch (e) {
      throw Exception('Error fetching appointments by payment status: $e');
    }
  }

  Future<String?> updatePaymentAmountAndStatus(
      String appointmentId, double amount, String paymentStatus) async {
    try {
      // ✅ อัปเดตข้อมูลการชำระเงิน
      await _firestore.collection('Appointments').doc(appointmentId).update({
        'payment_amount': amount,
        'payment_status': paymentStatus,
      });

      // ✅ ค้นหา patient_id สำหรับส่งการแจ้งเตือน
      final appointmentDoc =
          await _firestore.collection('Appointments').doc(appointmentId).get();

      if (!appointmentDoc.exists) {
        throw Exception('ไม่พบข้อมูลการนัดหมาย');
      }

      final patientId = appointmentDoc.data()?['patient_id'];
      if (patientId == null) {
        throw Exception('ไม่พบข้อมูลผู้ป่วยในนัดหมายนี้');
      }

      return patientId;
    } catch (e) {
      throw Exception('Error updating payment amount and status: $e');
    }
  }

// ✅ อนุมัติการชำระเงิน
  Future<void> approvePayment(String appointmentId) async {
    try {
      // ✅ ดึงข้อมูลการนัดหมาย
      final appointmentDoc =
          await _firestore.collection('Appointments').doc(appointmentId).get();
      final patientId = appointmentDoc.data()?['patient_id'] ?? '';

      if (patientId.isEmpty) {
        throw Exception('❌ ไม่พบข้อมูลผู้ป่วย');
      }

      // ✅ ดึงอีเมลของผู้ป่วยจาก Firestore
      DocumentSnapshot patientSnapshot =
          await _firestore.collection('User').doc(patientId).get();
      String patientEmail = patientSnapshot['email'];
      String patientName = patientSnapshot['first_name'] ?? 'ผู้ใช้';

      // ✅ อัปเดตสถานะการชำระเงินใน Firestore
      await _firestore.collection('Appointments').doc(appointmentId).update({
        'payment_status': 'ชำระเงินสำเร็จ',
        'status': 'ยืนยันแล้ว',
        'payment_date': Timestamp.now(),
      });

      // ✅ แจ้งเตือนผู้ป่วยผ่าน Firebase Cloud Messaging (FCM)
      unawaited(http.post(
        Uri.parse('${AppConfig.apiUrl}/notify-payment-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': patientId,
          'appointment_id': appointmentId,
          'status': 'ชำระเงินสำเร็จ',
        }),
      ));

      // ✅ สร้างข้อความอีเมลแจ้งเตือน
      String emailSubject = '✅ การชำระเงินของคุณได้รับการอนุมัติ';
      String emailBody = 'เรียนคุณ $patientName,\n\n'
          'การชำระเงินของท่านได้รับการยืนยันเรียบร้อยแล้ว.\n\n'
          'สถานะปัจจุบัน: **ชำระเงินสำเร็จ**\n'
          'หากท่านต้องการข้อมูลเพิ่มเติม กรุณาติดต่อเจ้าหน้าที่.\n\n'
          'ขอบคุณที่ใช้บริการ MediBridge\n'
          'ทีมงาน MediBridge';

      // ✅ ส่งอีเมลแจ้งเตือน
      unawaited(NotificationService.instance.sendEmailNotification(
        toEmail: patientEmail,
        subject: emailSubject,
        body: emailBody,
      ));

      debugPrint('✅ อนุมัติการชำระเงิน และส่งอีเมลแจ้งเตือนให้ผู้ป่วยสำเร็จ');
    } catch (e) {
      debugPrint('❌ Error approving payment: $e');
    }
  }

// ✅ ปฏิเสธการชำระเงิน
  Future<void> rejectPayment(String appointmentId) async {
    try {
      // ✅ ดึงข้อมูลการนัดหมาย
      final appointmentDoc =
          await _firestore.collection('Appointments').doc(appointmentId).get();
      final patientId = appointmentDoc.data()?['patient_id'] ?? '';

      if (patientId.isEmpty) {
        throw Exception('❌ ไม่พบข้อมูลผู้ป่วย');
      }

      // ✅ ดึงอีเมลของผู้ป่วยจาก Firestore
      DocumentSnapshot patientSnapshot =
          await _firestore.collection('User').doc(patientId).get();
      String patientEmail = patientSnapshot['email'];
      String patientName = patientSnapshot['first_name'] ?? 'ผู้ใช้';

      // ✅ อัปเดตสถานะการชำระเงินใน Firestore
      await _firestore.collection('Appointments').doc(appointmentId).update({
        'payment_status': 'รอการชำระเงิน',
      });

      // ✅ แจ้งเตือนผู้ป่วยผ่าน Firebase Cloud Messaging (FCM)
      unawaited(http.post(
        Uri.parse('${AppConfig.apiUrl}/notify-payment-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': patientId,
          'appointment_id': appointmentId,
          'status': 'ถูกปฏิเสธ',
        }),
      ));

      // ✅ สร้างข้อความอีเมลแจ้งเตือน
      String emailSubject = '⚠️ การชำระเงินของคุณถูกปฏิเสธ';
      String emailBody = 'เรียนคุณ $patientName,\n\n'
          'เราขอแจ้งให้ทราบว่าการชำระเงินของท่าน **ถูกปฏิเสธ**.\n\n'
          'กรุณาตรวจสอบข้อมูลการชำระเงินและทำรายการใหม่อีกครั้ง.\n'
          'หากท่านมีข้อสงสัย กรุณาติดต่อเจ้าหน้าที่โรงพยาบาล.\n\n'
          'ขอบคุณที่ใช้บริการ MediBridge\n'
          'ทีมงาน MediBridge';

      // ✅ ส่งอีเมลแจ้งเตือน
      unawaited(NotificationService.instance.sendEmailNotification(
        toEmail: patientEmail,
        subject: emailSubject,
        body: emailBody,
      ));

      debugPrint('✅ ปฏิเสธการชำระเงิน และส่งอีเมลแจ้งเตือนให้ผู้ป่วยสำเร็จ');
    } catch (e) {
      debugPrint('❌ Error rejecting payment: $e');
    }
  }

  // ดึงรายการตามสถานะการชำระเงิน
  Future<List<Map<String, dynamic>>> getAppointmentsWithDetailsByPaymentStatus(
      String paymentStatus) async {
    try {
      // Query นัดหมายตาม payment_status
      QuerySnapshot snapshot = await _firestore
          .collection('Appointments')
          .where('payment_status', isEqualTo: paymentStatus)
          .get();

      // เตรียมผลลัพธ์ที่เก็บข้อมูลนัดหมายพร้อมรายละเอียด
      List<Map<String, dynamic>> result = [];

      // Loop ผ่านเอกสารที่ดึงมา
      for (var doc in snapshot.docs) {
        AppointmentModel appointment = AppointmentModel.fromFirestore(doc);
        String patientId = appointment.patientId;
        String doctorId = appointment.doctorId;

        // 1. ดึง `user_id` ของผู้ป่วยจากคอลเลกชัน `Patients`
        DocumentSnapshot patientDoc =
            await _firestore.collection('Patients').doc(patientId).get();
        String patientUserId = patientDoc['user_id'];

        // 2. ดึง `user_id` ของแพทย์จากคอลเลกชัน `Doctors`
        DocumentSnapshot doctorDoc =
            await _firestore.collection('Doctors').doc(doctorId).get();
        String doctorUserId = doctorDoc['user_id'];

        // 3. ดึง `ชื่อ` และ `นามสกุล` ของผู้ป่วยจากคอลเลกชัน `User`
        DocumentSnapshot patientUserDoc =
            await _firestore.collection('User').doc(patientUserId).get();
        String patientName =
            '${patientUserDoc['first_name']} ${patientUserDoc['last_name']}';

        // 4. ดึง `ชื่อ` และ `นามสกุล` ของแพทย์จากคอลเลกชัน `User`
        DocumentSnapshot doctorUserDoc =
            await _firestore.collection('User').doc(doctorUserId).get();
        String doctorName =
            '${doctorUserDoc['first_name']} ${doctorUserDoc['last_name']}';

        // เพิ่มข้อมูลลงใน result
        result.add({
          'appointment': appointment,
          'patient_name': patientName,
          'doctor_name': doctorName,
          'payment_status': appointment.paymentStatus,
          'payment_amount': appointment.paymentAmount,
          'payment_slip_url': appointment.paymentSlipUrl,
        });
      }

      return result;
    } catch (e) {
      throw Exception('Error fetching appointments with details: $e');
    }
  }

  // ฟังก์ชันสำหรับดึงรายละเอียดของ Appointment
  Future<Map<String, dynamic>> getAppointmentDetails(
      String appointmentId) async {
    try {
      final doc =
          await _firestore.collection('Appointments').doc(appointmentId).get();
      final data = doc.data();

      if (data != null) {
        final patientId = data['patient_id'];
        final doctorId = data['doctor_id'];

        // ดึงข้อมูลผู้ป่วยและแพทย์
        final patientDoc =
            await _firestore.collection('Patients').doc(patientId).get();
        final doctorDoc =
            await _firestore.collection('Doctors').doc(doctorId).get();
        final patientUserDoc = await _firestore
            .collection('User')
            .doc(patientDoc['user_id'])
            .get();
        final doctorUserDoc =
            await _firestore.collection('User').doc(doctorDoc['user_id']).get();

        return {
          'payment_slip_url': data['payment_slip_url'],
          'patient_name':
              '${patientUserDoc['first_name']} ${patientUserDoc['last_name']}',
          'doctor_name':
              '${doctorUserDoc['first_name']} ${doctorUserDoc['last_name']}',
          'appointment_date': data['appointment_date'], // เพิ่ม
          'appointment_time': data['appointment_time'], // เพิ่ม
        };
      } else {
        throw Exception('Appointment not found');
      }
    } catch (e) {
      throw Exception('Error fetching appointment details: $e');
    }
  }

  Future<bool> isTimeSlotAvailable({
    required String doctorId,
    required DateTime date,
    required String time,
  }) async {
    // ตรวจสอบใน collection Appointments ว่าเวลานี้ถูกใช้งานหรือไม่
    QuerySnapshot appointments = await FirebaseFirestore.instance
        .collection('Appointments')
        .where('doctor_id', isEqualTo: doctorId) // ตรวจสอบ doctorId
        .where('appointment_date', isEqualTo: date) // ตรวจสอบวันที่
        .where('appointment_time', isEqualTo: time) // ตรวจสอบเวลา
        .get();

    // ถ้าพบว่า appointments.docs ไม่ว่าง แสดงว่าเวลานี้ถูกจองแล้ว
    return appointments.docs.isEmpty;
  }

  Future<void> updateDoctorSchedule({
    required String doctorId,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('DoctorSchedules')
          .where('doctor_id', isEqualTo: doctorId)
          .where('date', isEqualTo: date.toIso8601String())
          .get();

      if (snapshot.docs.isNotEmpty) {
        // หากมีตารางในวันนั้นอยู่แล้ว ให้ทำการอัปเดต
        await snapshot.docs.first.reference.update({
          'start_time': startTime,
          'end_time': endTime,
        });
      } else {
        // หากยังไม่มีตารางในวันนั้น ให้เพิ่มใหม่
        await FirebaseFirestore.instance.collection('DoctorSchedules').add({
          'doctor_id': doctorId,
          'date': date.toIso8601String(),
          'start_time': startTime,
          'end_time': endTime,
        });
      }
    } catch (e) {
      throw Exception('Error updating schedule: $e');
    }
  }

// เมธอดใหม่รวม update status และส่งแจ้งเตือน (สำหรับเจ้าหน้าที่และแพทย์)
Future<void> updateAppointmentAndNotify(String appointmentId,
    String newStatus, Map<String, dynamic> appointment) async {
  try {
    // 1. อัปเดตสถานะนัดหมายและข้อมูลเพิ่มเติมใน Firestore
    Map<String, dynamic> updateData = {'status': newStatus};
    if (newStatus == 'รอชำระเงิน') {
      updateData.addAll({
        'payment_amount': 0,
        'payment_status': 'รอเพิ่มรายการชำระเงิน',
        'payment_date': null,
      });
    } else if (newStatus == 'ยกเลิก') {
      updateData.addAll({
        'payment_amount': 0,
        'payment_status': 'ยกเลิก',
        'payment_date': null,
      });
    }
    await _firestore.collection('Appointments').doc(appointmentId).update(updateData);

    unawaited(http.post(
      Uri.parse('http://172.20.10.2:5001/appointment-status-notification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "patient_id": appointment['patient_id'],
        "doctor_id": appointment['doctor_id'],
        "status": newStatus,
        "appointment_date": appointment['appointment_date'],
        "appointment_time": appointment['appointment_time']
      }),
    ));

    // 3. ดึงข้อมูลแพทย์จาก Firestore เพื่อรับอีเมล
    DocumentSnapshot doctorSnapshot = await _firestore
        .collection('User')
        .doc(appointment['doctor_id'])
        .get();
    String? doctorEmail = doctorSnapshot.exists ? doctorSnapshot['email'] : null;

    // 4. ส่ง push notification ไปให้แพทย์ (และ/หรือผู้ป่วย) เท่านั้น
    // หากเป็นการอัปเดตนัดหมาย (ยืนยัน/ยกเลิก) ไม่ต้องส่ง push notification ให้เจ้าหน้าที่
    DateTime appDate;
    if (appointment['appointment_date'] is Timestamp) {
      appDate = (appointment['appointment_date'] as Timestamp).toDate();
    } else if (appointment['appointment_date'] is String) {
      appDate = DateFormat('dd/MM/yyyy').parse(appointment['appointment_date']);
    } else {
      appDate = DateTime.now();
    }

    // 5. ส่งอีเมลแจ้งเตือนให้แพทย์ (เฉพาะกรณีที่สถานะไม่ใช่ "ยกเลิก")
    if (doctorEmail != null && newStatus != 'ยกเลิก') {
      String doctorSubject = '📅 แจ้งเตือน: รายการนัดหมายใหม่';
      String doctorBody = 'เรียนคุณหมอ,\n\n'
          'มีนัดหมายใหม่ในวันที่ ${appointment['appointment_date']} เวลา ${appointment['appointment_time']} '
          'กรุณาตรวจสอบรายละเอียดในระบบ MediBridge\n\n'
          'ขอบคุณครับ/ค่ะ\nMediBridge Team';

      unawaited(NotificationService.instance.sendEmailNotification(
        toEmail: doctorEmail,
        subject: doctorSubject,
        body: doctorBody,
      ));
      print('✅ ส่งแจ้งเตือนให้ Doctor สำเร็จ');
    } else {
      print('❌ ไม่พบอีเมลของ Doctor ในระบบ');
    }
  } catch (e) {
    throw Exception('❌ Error updating appointment and sending notifications: $e');
  }
}
}
