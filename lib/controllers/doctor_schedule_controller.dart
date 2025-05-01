import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medibridge_application/services/doctor_schedule_service.dart';

import '../services/doctor_service.dart';

class DoctorScheduleController {
  final DoctorService _doctorService = DoctorService();
  final DoctorScheduleService _doctorScheduleService = DoctorScheduleService();

  Future<List<Map<String, dynamic>>> getSchedulesForDateWithUserName(
      DateTime date, String dayOfWeek) async {
    debugPrint("Fetching schedules for date: $date and dayOfWeek: $dayOfWeek");
    final schedules =
        await _doctorService.getDoctorSchedulesWithUserName(date, dayOfWeek);
    debugPrint("Fetched schedules: $schedules");
    return schedules;
  }

  Future<List<Map<String, dynamic>>> getSchedulesByPartialName(
    String name,
    DateTime selectedDate, // ADDED
  ) async {
    debugPrint('Fetching schedules for name: $name, date: $selectedDate');
    return await _doctorService.searchByPartialName(name, selectedDate);
  }

  Future<Map<String, String?>> getScheduleForDate(
      String doctorId, DateTime date) async {
    return await _doctorService.getScheduleForDate(doctorId, date);
  }

// ✅ แก้ใน _saveSchedule() ให้เรียก notifyDoctorScheduleUpdated
// ✅ เพิ่ม notifyDoctorScheduleUpdated ใน _saveSchedule()
  Future<void> saveCustomSchedule({
    required String doctorId,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) async {
    // 📝 1. บันทึกตารางเวร
    await _doctorService.saveCustomSchedule(
      doctorId: doctorId,
      date: date,
      startTime: startTime,
      endTime: endTime,
    );

    // 🛎️ 2. แจ้งเตือนแพทย์
    unawaited(_doctorScheduleService.notifyDoctorScheduleUpdated(
      doctorId: doctorId,
      date: date,
      startTime: startTime,
      endTime: endTime,
    ));
  }
}
