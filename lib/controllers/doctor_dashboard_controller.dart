import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // ใช้ debugPrint

class DoctorDashboardController {
  final String doctorId;
  double totalEarnings = 0;
  double yearlyEarnings = 0;
  double monthlyEarnings = 0;
  double weeklyEarnings = 0;
  double averageRating = 0;
  int totalAppointments = 0;
  List<Map<String, dynamic>> feedbacks = [];

  // ข้อมูลสำหรับกราฟ
  List<double> weeklyData = List.filled(7, 0); // รายได้แต่ละวันของสัปดาห์ (Mon-Sun)
  List<double> monthlyData = List.filled(4, 0); // รายได้แต่ละสัปดาห์ของเดือน
  List<double> yearlyData = List.filled(12, 0); // รายได้แต่ละเดือนของปี

  DoctorDashboardController({required this.doctorId});

  Future<void> fetchDashboardData() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      debugPrint("📅 Fetching data for doctor ID: $doctorId (current year: 2025)");
      debugPrint("📆 Start of Month: $startOfMonth");
      debugPrint("📆 Start of Week: $startOfWeek");

      // 🔹 ดึงข้อมูลเฉพาะของแพทย์ที่ล็อกอิน และชำระเงินสำเร็จ
      final appointmentsQuery = await FirebaseFirestore.instance
          .collection('Appointments')
          .where('doctor_id', isEqualTo: doctorId)
          .where('payment_status', isEqualTo: "ชำระเงินสำเร็จ")
          .get();

      totalAppointments = 0;
      double total = 0;
      double yearlyTotal = 0;
      double monthlyTotal = 0;
      double weeklyTotal = 0;

      // เคลียร์ข้อมูลกราฟก่อนโหลดใหม่
      weeklyData.fillRange(0, weeklyData.length, 0);
      monthlyData.fillRange(0, monthlyData.length, 0);
      yearlyData.fillRange(0, yearlyData.length, 0);

      debugPrint("🔍 Found ${appointmentsQuery.docs.length} appointments.");

      for (var doc in appointmentsQuery.docs) {
        final data = doc.data();
        final appointmentId = data['appointment_id'] ?? "Unknown";
        final paymentAmount = (data['payment_amount'] as num?)?.toDouble() ?? 0;
        final paymentDate = (data['payment_date'] as Timestamp?)?.toDate();

        if (paymentDate == null) {
          debugPrint("⚠️ Skipped Appointment: $appointmentId (Invalid Date)");
          continue;
        }
        if (paymentDate.year != 2025) {
          debugPrint("⏩ Skipped Appointment: $appointmentId (Not in 2025)");
          continue;
        }

        totalAppointments++;
        total += paymentAmount;
        yearlyTotal += paymentAmount;
        if (paymentDate.isAfter(startOfMonth)) monthlyTotal += paymentAmount;
        if (paymentDate.isAfter(startOfWeek)) weeklyTotal += paymentAmount;

        // คำนวณรายได้แยกตามช่วงเวลา
        int weekdayIndex = paymentDate.weekday - 1; // Monday = 0, Sunday = 6
        weeklyData[weekdayIndex] += paymentAmount;

        int weekOfMonth = (paymentDate.day / 7).ceil() - 1; // Week 1-4
        if (weekOfMonth >= 0 && weekOfMonth < 4) {
          monthlyData[weekOfMonth] += paymentAmount;
        }

        int monthIndex = paymentDate.month - 1; // Jan = 0, Dec = 11
        yearlyData[monthIndex] += paymentAmount;

        debugPrint("✅ Appointment: $appointmentId");
        debugPrint("   📅 Date: $paymentDate");
        debugPrint("   💰 Amount: ฿$paymentAmount");
        debugPrint("   📆 Weekday Index: $weekdayIndex");
        debugPrint("   📆 Week of Month: $weekOfMonth");
        debugPrint("   📆 Month Index: $monthIndex");
        debugPrint("------------------------------------------");
      }

      // อัปเดตค่ารวม
      totalEarnings = total;
      yearlyEarnings = yearlyTotal;
      monthlyEarnings = monthlyTotal;
      weeklyEarnings = weeklyTotal;

      debugPrint("💰 Total Earnings: ฿$totalEarnings");
      debugPrint("📅 Weekly Earnings: ฿$weeklyEarnings");
      debugPrint("📆 Monthly Earnings: ฿$monthlyEarnings");
      debugPrint("🗓 Yearly Earnings: ฿$yearlyEarnings");
      debugPrint("📋 Total Appointments: $totalAppointments");

      // ดึงข้อมูลแพทย์ (Feedbacks)
      final doctorDoc = await FirebaseFirestore.instance
          .collection('Doctors')
          .doc(doctorId)
          .get();

      if (doctorDoc.exists) {
        final doctorData = doctorDoc.data();
        final feedbackMap = doctorData?['feedbacks'] ?? {};
        double totalRating = 0;
        int ratingCount = 0;

        feedbacks = [];
        feedbackMap.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final comment = value['comment'] ?? "No Comment";
            final rating = (value['rating'] as num?)?.toDouble() ?? 0;

            feedbacks.add({'comment': comment, 'rating': rating});
            totalRating += rating;
            ratingCount++;
          }
        });

        if (ratingCount > 0) {
          averageRating = totalRating / ratingCount;
        }
      }

      debugPrint("⭐ Average Rating: ${averageRating.toStringAsFixed(2)}");

    } catch (e, stacktrace) {
      debugPrint("❌ Error fetching dashboard data: $e");
      debugPrint("🔍 Stacktrace: $stacktrace");
    }
  }
}
