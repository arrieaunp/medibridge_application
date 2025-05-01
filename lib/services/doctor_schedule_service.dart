import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medibridge_application/config.dart';
import 'package:medibridge_application/services/notification_service.dart';

class DoctorScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchSchedules(
      String doctorId, DateTime startOfWeek, DateTime endOfWeek) async {
    final List<Map<String, dynamic>> scheduleList = [];

    try {
      // ดึงข้อมูลจาก Doctors collection
      final doctorDoc = await FirebaseFirestore.instance
          .collection('Doctors')
          .doc(doctorId)
          .get();

      if (!doctorDoc.exists || doctorDoc.data() == null) {
        throw Exception('Doctor data not found');
      }

      final doctorData = doctorDoc.data()!;
      final availableDays = List<String>.from(doctorData['available_days']);
      final availableHours = doctorData['available_hours'];

      // สร้างตารางเวรรายวัน
      for (int i = 0; i < 7; i++) {
        final currentDate = startOfWeek.add(Duration(days: i));
        final currentDayName = _getThaiDayName(currentDate.weekday);

        if (availableDays.contains(currentDayName)) {
          // แปลงวันที่ปัจจุบันเป็นฟอร์แมต Firestore
          final formattedDate = formatDateToFirestoreString(currentDate);

          // ดึงข้อมูลจาก DoctorSchedules
          final scheduleSnapshot = await FirebaseFirestore.instance
              .collection('DoctorSchedules')
              .where('doctor_id', isEqualTo: doctorId)
              .where('date', isEqualTo: formattedDate)
              .get();

          final override = scheduleSnapshot.docs.isNotEmpty
              ? scheduleSnapshot.docs.first.data()
              : null;

          // เพิ่มข้อมูลลงในตาราง
          scheduleList.add({
            'date': currentDate,
            'start_time': override?['start_time'] ?? availableHours['start'],
            'end_time': override?['end_time'] ?? availableHours['end'],
            'is_override': override != null,
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching schedules: $e');
    }

    return scheduleList;
  }

  String _getThaiDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'วันจันทร์';
      case DateTime.tuesday:
        return 'วันอังคาร';
      case DateTime.wednesday:
        return 'วันพุธ';
      case DateTime.thursday:
        return 'วันพฤหัสบดี';
      case DateTime.friday:
        return 'วันศุกร์';
      case DateTime.saturday:
        return 'วันเสาร์';
      case DateTime.sunday:
        return 'วันอาทิตย์';
      default:
        return '';
    }
  }

  // ฟังก์ชันแปลง DateTime เป็นรูปแบบวันที่ (ว/ด/ป)
  static String formatDate(DateTime date) {
    final thaiDateFormat = DateFormat('d/M/yyyy');
    return thaiDateFormat.format(date);
  }

  String formatDateToFirestoreString(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return "$year-$month-${day}T00:00:00.000";
  }

  static String formatThaiDate(DateTime date) {
    final thaiMonthNames = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม'
    ];
    final year = date.year; // แปลงปีเป็น พ.ศ. ให้ +543
    final month = thaiMonthNames[date.month - 1];
    final day = date.day;

    return '$day $month $year';
  }

  // ฟังก์ชันแปลงวันที่เป็นรูปแบบ "3 February 2025"
  static String formatEnglishDate(DateTime date) {
    final dateFormat = DateFormat('d MMMM yyyy');
    return dateFormat.format(date);
  }

  // 🆕 ฟังก์ชันสำหรับบันทึกคำร้องขอเปลี่ยนตารางเวร (เรียก API Backend)
  Future<void> requestScheduleChange({
    required String doctorId,
    required Map<String, dynamic> schedule,
    required String reason,
  }) async {
    try {
      // ✅ ดึงข้อมูลแพทย์จาก Firestore (ใช้ user_id แทน doctor_id)
      DocumentSnapshot doctorSnapshot =
          await _firestore.collection('User').doc(doctorId).get();

      if (!doctorSnapshot.exists) {
        throw Exception('❌ ไม่พบข้อมูลแพทย์ใน Firestore');
      }

      String doctorName =
          "${doctorSnapshot['first_name']} ${doctorSnapshot['last_name']}";

      // ✅ เรียกการแจ้งเตือนแบบ Background (ไม่รอผล)
      unawaited(_notifyStaffScheduleChangeBackground(
        doctorId: doctorId,
        doctorName: doctorName,
        schedule: schedule,
        reason: reason,
      ));

      // ✅ แจ้งสำเร็จให้ผู้ใช้ทันที ไม่ต้องรอแจ้งเตือนเสร็จ
      debugPrint("✅ ส่งคำร้องขอเปลี่ยนตารางเวรสำเร็จ (แจ้งเตือน Background)");
    } catch (e) {
      debugPrint("❌ เกิดข้อผิดพลาดในการส่งคำร้องขอ: $e");
    }
  }

  Future<void> _notifyStaffScheduleChangeBackground({
    required String doctorId,
    required String doctorName,
    required Map<String, dynamic> schedule,
    required String reason,
  }) async {
    try {
      // ดึงอีเมลของเจ้าหน้าที่จาก Firestore
      QuerySnapshot staffSnapshot = await _firestore
          .collection('User')
          .where('role', isEqualTo: 'Staff')
          .limit(1)
          .get();

      if (staffSnapshot.docs.isNotEmpty) {
        String staffEmail = staffSnapshot.docs.first['email'];

        // ส่งอีเมลแจ้งเตือนถึงเจ้าหน้าที่แบบ background
        unawaited(NotificationService.instance.sendEmailNotification(
          toEmail: staffEmail,
          subject: '📅 แจ้งเตือน: คำร้องขอเปลี่ยนตารางเวรจากแพทย์',
          body: '''
เรียนเจ้าหน้าที่,

แพทย์ **$doctorName** ได้ส่งคำร้องขอเปลี่ยนตารางเวร.

- 📅 วันที่: ${_formatDate(schedule['date'])}
- ⏰ เวลา: ${schedule['time']}
- 📌 เหตุผล: $reason

กรุณาตรวจสอบที่ระบบ MediBridge.

ขอบคุณครับ/ค่ะ  
ทีมงาน MediBridge''',
        ));

        debugPrint("✅ (Background) ส่งอีเมลแจ้งเจ้าหน้าที่สำเร็จ");
      } else {
        debugPrint("⚠️ (Background) ไม่พบอีเมลเจ้าหน้าที่");
      }

      // แจ้งเตือนผ่าน FCM แบบ background
      unawaited(http.post(
        Uri.parse('${AppConfig.apiUrl}/notify-schedule-change-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doctor_id': doctorId,
          'schedule_date': (schedule['date'] as DateTime).toIso8601String(),
          'schedule_time': schedule['time'],
          'reason': reason,
        }),
      ));

      debugPrint("✅ (Background) แจ้งเตือน FCM เจ้าหน้าที่สำเร็จ");
    } catch (e) {
      debugPrint("❌ (Background) แจ้งเตือนเจ้าหน้าที่ล้มเหลว: $e");
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

// 🆕 แจ้งเตือนแพทย์เมื่อเจ้าหน้าที่เปลี่ยนตารางเวร
  Future<void> notifyDoctorScheduleUpdated({
    required String doctorId,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      // ✅ ดึงข้อมูลแพทย์จาก `User` collection
      DocumentSnapshot doctorSnapshot =
          await _firestore.collection('User').doc(doctorId).get();

      if (!doctorSnapshot.exists) {
        throw Exception('❌ ไม่พบข้อมูลแพทย์ใน Firestore');
      }

      String doctorName =
          "${doctorSnapshot['first_name']} ${doctorSnapshot['last_name']}";
      String doctorEmail = doctorSnapshot['email'] ?? '';

      if (doctorEmail.isEmpty) {
        throw Exception('❌ ไม่พบอีเมลของแพทย์');
      }

      // ✅ สร้างอีเมลแจ้งเตือน
      String emailSubject = '📅 แจ้งเตือน: ตารางเวรของคุณถูกปรับปรุง';
      String emailBody = 'เรียนคุณ $doctorName,\n\n'
          'เจ้าหน้าที่โรงพยาบาลได้เปลี่ยนแปลงตารางเวรของคุณในระบบ MediBridge.\n\n'
          '- 📅 วันที่: ${_formatDate(date)}\n'
          '- ⏰ เวลา: $startTime - $endTime\n\n'
          'กรุณาตรวจสอบตารางเวรของคุณในระบบ MediBridge.\n\n'
          'ขอบคุณครับ/ค่ะ\nทีมงาน MediBridge';

      // ✅ ส่งอีเมลแจ้งเตือนถึงแพทย์
      await NotificationService.instance.sendEmailNotification(
        toEmail: doctorEmail,
        subject: emailSubject,
        body: emailBody,
      );

      debugPrint("✅ ส่งอีเมลแจ้งเตือนตารางเวรใหม่ให้แพทย์สำเร็จ");

      // ✅ แจ้งเตือนผ่าน FCM
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/notify-doctor-schedule-updated'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doctor_id': doctorId,
          'schedule_date': date.toIso8601String(),
          'start_time': startTime,
          'end_time': endTime,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ แจ้งเตือนแพทย์ผ่าน FCM สำเร็จ");
      } else {
        debugPrint(
            "⚠️ แจ้งเตือนแพทย์ผ่าน FCM ล้มเหลว: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ เกิดข้อผิดพลาดในการแจ้งเตือนแพทย์: $e");
    }
  }
}
