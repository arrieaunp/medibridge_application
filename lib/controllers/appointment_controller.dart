import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medibridge_application/models/appointment_model.dart';
import 'package:medibridge_application/services/appointment_service.dart';
import 'package:medibridge_application/services/notification_service.dart';

class AppointmentController extends ChangeNotifier {
  final AppointmentService _service = AppointmentService();
  final TextEditingController paymentAmountController = TextEditingController();

  List<AppointmentModel> _appointments = [];
  List<AppointmentModel> get appointments => _appointments;

  List<Map<String, dynamic>>? _cachedDoctors;

  Future<bool> isTimeSlotAvailable({
    required String doctorId,
    required DateTime date,
    required String time,
  }) async {
    try {
      // Debug: Log ค่าที่จะ Query
      debugPrint(
          'Debug: Checking time slot for doctor_id: $doctorId, date: $date, time: $time');

      // Query Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Appointments')
          .where('doctor_id', isEqualTo: doctorId)
          .where('appointment_date',
              isEqualTo: Timestamp.fromDate(date)) // ใช้ Timestamp
          .where('appointment_time', isEqualTo: time)
          .where('status', whereIn: [
        'รอยืนยัน',
        'รอชำระเงิน',
        'ยืนยันแล้ว'
      ]) // เฉพาะสถานะที่บล็อก
          .get();

      // Debug: Log ผลลัพธ์ของ Query
      debugPrint('Found ${snapshot.docs.length} conflicting appointments.');

      // หากไม่มีเอกสารในเวลานั้น แสดงว่าสามารถนัดหมายได้
      return snapshot.docs.isEmpty;
    } catch (e) {
      // Debug: Log ข้อผิดพลาดที่เกิดขึ้น
      debugPrint('Error checking time slot availability: $e');
      return false;
    }
  }

  Future<void> fetchPendingAppointments() async {
    try {
      _appointments = await _service.getPendingAppointments();
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
    }
  }

  DateTime? selectedDate;
  String? selectedTime;

  DateTime focusedDay = DateTime.now();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> getAvailableTimes() {
    return ['08:00', '09:00', '10:00', '11:00', '13:00', '14:00', '15:00'];
  }

  void selectDate(DateTime selectedDay) {
    selectedDate = selectedDay;
  }

  void selectTime(String time) {
    selectedTime = time;
  }

  bool canProceed() {
    return selectedDate != null && selectedTime != null;
  }

  String getSelectedDate() {
    return selectedDate != null
        ? DateFormat('dd/MM/yyyy').format(selectedDate!)
        : 'ไม่ระบุ';
  }

  String getSelectedTime() {
    return selectedTime ?? 'ไม่ระบุ';
  }

  Future<List<Map<String, dynamic>>> getAvailableDoctors() async {
    if (selectedDate == null || selectedTime == null) {
      debugPrint("Error: selectedDate or selectedTime is null.");
      return [];
    }
    if (_cachedDoctors != null) {
      debugPrint("Returning cached doctors.");
      return _cachedDoctors!;
    }

    QuerySnapshot doctorSnapshot = await _firestore.collection('Doctors').get();
    List<Map<String, dynamic>> availableDoctors = [];

    DateTime selectedTimeParsed = DateFormat('HH:mm').parse(selectedTime!);
    String formattedSelectedDate =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").format(selectedDate!);

    debugPrint("Selected Date (formatted): $formattedSelectedDate");
    debugPrint("Selected Time: $selectedTime (parsed: $selectedTimeParsed)");

    for (var doc in doctorSnapshot.docs) {
      Map<String, dynamic> doctorData = doc.data() as Map<String, dynamic>;

      if (doctorData.containsKey('user_id') &&
          doctorData.containsKey('available_days') &&
          doctorData.containsKey('available_hours') &&
          doctorData['available_hours'].containsKey('start') &&
          doctorData['available_hours'].containsKey('end')) {
        bool isAvailableForSelectedTime = false;

        // ตรวจสอบข้อมูลใน DoctorSchedules
        debugPrint(
            "Querying DoctorSchedules with doctor_id: ${doctorData['doctor_id']} and date: $formattedSelectedDate");

        QuerySnapshot scheduleSnapshot = await _firestore
            .collection('DoctorSchedules')
            .where('doctor_id', isEqualTo: doctorData['doctor_id'])
            .where('date', isEqualTo: formattedSelectedDate)
            .get();

        debugPrint(
            "Checking DoctorSchedules for doctor: ${doctorData['doctor_id']} -> Found: ${scheduleSnapshot.docs.isNotEmpty}");

        if (scheduleSnapshot.docs.isNotEmpty) {
          // ใช้เวลาใน DoctorSchedules
          Map<String, dynamic> scheduleData =
              scheduleSnapshot.docs.first.data() as Map<String, dynamic>;

          DateTime scheduleStartTime =
              DateFormat('HH:mm').parse(scheduleData['start_time']);
          DateTime scheduleEndTime =
              DateFormat('HH:mm').parse(scheduleData['end_time']);

          debugPrint(
              "Using DoctorSchedules: ${scheduleData['start_time']} - ${scheduleData['end_time']} for doctor: ${doctorData['doctor_id']}");

          isAvailableForSelectedTime =
              selectedTimeParsed.isAtSameMomentAs(scheduleStartTime) ||
                  (selectedTimeParsed.isAfter(scheduleStartTime) &&
                      selectedTimeParsed.isBefore(scheduleEndTime)) ||
                  selectedTimeParsed.isAtSameMomentAs(scheduleEndTime);

          if (isAvailableForSelectedTime) {
            debugPrint(
                "Doctor ${doctorData['doctor_id']} is available based on DoctorSchedules.");
          }
        }

        // ใช้ Default hours ใน Doctors หากไม่มีข้อมูลใน DoctorSchedules
        if (!isAvailableForSelectedTime && scheduleSnapshot.docs.isEmpty) {
          if (doctorData['available_days']
              .contains(DateFormat('EEEE', 'th').format(selectedDate!))) {
            DateTime doctorStartTime = DateFormat('HH:mm')
                .parse(doctorData['available_hours']['start']);
            DateTime doctorEndTime =
                DateFormat('HH:mm').parse(doctorData['available_hours']['end']);

            debugPrint(
                "Default hours: ${doctorData['available_hours']['start']} - ${doctorData['available_hours']['end']} for doctor: ${doctorData['doctor_id']}");
            debugPrint("Selected time: $selectedTimeParsed");

            isAvailableForSelectedTime =
                selectedTimeParsed.isAtSameMomentAs(doctorStartTime) ||
                    (selectedTimeParsed.isAfter(doctorStartTime) &&
                        selectedTimeParsed.isBefore(doctorEndTime)) ||
                    selectedTimeParsed.isAtSameMomentAs(doctorEndTime);

            if (isAvailableForSelectedTime) {
              debugPrint(
                  "Doctor ${doctorData['doctor_id']} is available based on Default hours.");
            }
          }
        }

        // เพิ่มแพทย์ในรายการถ้าพบว่าเวลาตรง
        if (isAvailableForSelectedTime) {
          QuerySnapshot userSnapshot = await _firestore
              .collection('User')
              .where('user_id', isEqualTo: doctorData['user_id'])
              .get();

          if (userSnapshot.docs.isNotEmpty) {
            Map<String, dynamic> userData =
                userSnapshot.docs.first.data() as Map<String, dynamic>;

            doctorData['first_name'] = userData['first_name'];
            doctorData['last_name'] = userData['last_name'];
            doctorData['profile_pic'] = userData['profile_pic'];
          }

          availableDoctors.add(doctorData);
          debugPrint(
              "Doctor ${doctorData['doctor_id']} added to available list.");
        } else {
          debugPrint(
              "Doctor ${doctorData['doctor_id']} is not available for the selected time.");
        }
      }
    }

    debugPrint(
        "Final Available Doctors: ${availableDoctors.map((doc) => doc['doctor_id']).toList()}");
    _cachedDoctors = availableDoctors;
    return availableDoctors;
  }

  Future<void> confirmAppointmentFromPatient({
    required String patientId,
    required String doctorId,
    required DateTime appointmentDate,
    required String appointmentTime,
  }) async {
    try {
      // ✅ ตรวจสอบว่าช่วงเวลานี้ยังว่างหรือไม่
      final isAvailable = await isTimeSlotAvailable(
        doctorId: doctorId,
        date: appointmentDate,
        time: appointmentTime,
      );

      if (!isAvailable) {
        throw Exception('❌ เวลานี้ถูกจองแล้ว กรุณาเลือกช่วงเวลาอื่น');
      }

      // ✅ หากว่าง ให้บันทึกการนัดหมาย
      String appointmentId = _firestore.collection('Appointments').doc().id;

      await _firestore.collection('Appointments').doc(appointmentId).set({
        'appointment_id': appointmentId,
        'patient_id': patientId,
        'doctor_id': doctorId,
        'appointment_date': Timestamp.fromDate(appointmentDate),
        'appointment_time': appointmentTime,
        'status': 'รอยืนยัน',
        'payment_amount': 0.0,
        'payment_status': 'ยังไม่ชำระ',
        'payment_date': null,
      });

      debugPrint('✅ [MyApp] Appointment saved: $appointmentId');

      // ✅ ส่งแจ้งเตือนแบบ Asynchronous (ไม่ต้องรอให้เสร็จ)
      _sendAsyncNotifications(
          appointmentId, doctorId, appointmentDate, appointmentTime);
    } catch (e) {
      debugPrint('❌ Error adding appointment: $e');
      throw Exception('Error adding appointment: $e');
    }
  }

  // ✅ ฟังก์ชันส่งแจ้งเตือนแบบ Background Task
  Future<void> _sendAsyncNotifications(String appointmentId, String doctorId,
      DateTime appointmentDate, String appointmentTime) async {
    try {
      // ✅ ส่งแจ้งเตือนผ่าน FCM โดยไม่ต้องรอ
      unawaited(NotificationService.instance.sendNewAppointmentNotification(
        appointmentId,
        appointmentDate,
        appointmentTime,
      ));

      // ✅ ดึงอีเมลของ Staff และ Doctor พร้อมกันแบบ Asynchronous
      Future<QuerySnapshot> staffFuture = _firestore
          .collection('User')
          .where('role', isEqualTo: 'Staff')
          .limit(1)
          .get();

      Future<DocumentSnapshot> doctorFuture =
          _firestore.collection('User').doc(doctorId).get();

      // ✅ รอให้ทั้งสองอันโหลดเสร็จ
      final results = await Future.wait([staffFuture, doctorFuture]);

      QuerySnapshot staffSnapshot = results[0] as QuerySnapshot;
      DocumentSnapshot doctorSnapshot = results[1] as DocumentSnapshot;

      String? staffEmail = staffSnapshot.docs.isNotEmpty
          ? staffSnapshot.docs.first['email']
          : null;
      String? doctorEmail =
          doctorSnapshot.exists ? doctorSnapshot['email'] : null;

      if (staffEmail != null) {
        String staffSubject = '📅 แจ้งเตือน: มีการนัดหมายใหม่จากผู้ป่วย';
        String staffBody =
            'เรียนเจ้าหน้าที่,\n\nมีการนัดหมายใหม่เข้ามาในระบบ.\n\n'
            '- วันที่: ${_formatDate(appointmentDate)}\n'
            '- เวลา: $appointmentTime\n'
            '- กรุณาตรวจสอบและยืนยันการนัดหมายผ่านระบบ MediBridge\n\n'
            'ขอบคุณครับ/ค่ะ\nMediBridge Team';

        unawaited(NotificationService.instance.sendEmailNotification(
          toEmail: staffEmail,
          subject: staffSubject,
          body: staffBody,
        ));
        debugPrint('✅ ส่งอีเมลแจ้งเตือนให้ Staff สำเร็จ');
      } else {
        debugPrint('❌ ไม่พบอีเมลของ Staff ในระบบ');
      }
    } catch (e) {
      debugPrint('❌ Error sending notifications: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<List<Map<String, dynamic>>> getAppointmentsForPatient(
      String patientId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Appointments')
          .where('patient_id', isEqualTo: patientId)
          .get();

      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
      return [];
    }
  }

  //ดึงรายชื่อแพทย์ มาแสดงในหน้า status
  Future<Map<String, dynamic>?> getDoctorDetails(String doctorId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('User')
          .where('user_id', isEqualTo: doctorId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data() as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error fetching doctor details: $e');
    }
    return null;
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _service.updateAppointmentStatus(appointmentId, 'ยกเลิก');
      debugPrint('Appointment $appointmentId has been cancelled.');
    } catch (e) {
      debugPrint('Error cancelling appointment: $e');
      throw Exception('Error cancelling appointment: $e');
    }
  }

  Future<Map<String, dynamic>> fetchPaymentDetails(String appointmentId) async {
    try {
      DocumentSnapshot appointmentDoc =
          await _service.getAppointmentById(appointmentId);

      if (!appointmentDoc.exists) {
        throw Exception('Appointment not found');
      }

      AppointmentModel appointment =
          AppointmentModel.fromFirestore(appointmentDoc);

      String patientName =
          await _service.getUserNameById(appointment.patientId);
      String doctorName = await _service.getUserNameById(appointment.doctorId);

      return {
        'patient_name': patientName,
        'doctor_name': doctorName,
        'appointment_date': DateFormat('dd MMMM yyyy', 'th')
            .format(appointment.appointmentDate),
        'appointment_time': appointment.appointmentTime,
        'payment_amount':
            appointment.paymentAmount ?? 0, // คืนค่า payment_amount
        'payment_status': appointment.paymentStatus ?? 'รอเพิ่มรายการชำระเงิน',
      };
    } catch (e) {
      debugPrint('Error fetching payment details: $e');
      throw Exception('Error fetching payment details');
    }
  }

  Future<void> savePayment(String appointmentId, double amount) async {
    if (paymentAmountController.text.isEmpty) {
      throw Exception('กรุณากรอกจำนวนเงิน');
    }

    double amount = double.parse(paymentAmountController.text);

    // ✅ อัปเดตข้อมูลการชำระเงินใน Firestore
    await _service.updatePaymentAmountAndStatus(
      appointmentId,
      amount,
      'รอการชำระเงิน',
    );

    // ✅ ดึง patient_id จากเอกสารการนัดหมาย
    final appointmentDoc = await FirebaseFirestore.instance
        .collection('Appointments')
        .doc(appointmentId)
        .get();

    if (!appointmentDoc.exists) {
      throw Exception('ไม่พบข้อมูลการนัดหมาย');
    }

    final patientId = appointmentDoc.data()?['patient_id'];
    if (patientId == null) {
      throw Exception('ไม่พบข้อมูลผู้ป่วย');
    }

    // ✅ ส่งแจ้งเตือนผู้ป่วยเรื่องค่ารักษาพยาบาล (ไม่มี due_date)
    unawaited(NotificationService.instance.sendPaymentDueNotificationToPatient(
      patientId: patientId,
      amount: amount,
    ));
  }
}
