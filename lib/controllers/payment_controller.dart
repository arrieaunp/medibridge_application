import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:medibridge_application/config.dart';
import 'package:medibridge_application/services/notification_service.dart';

class PaymentController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final patientId = FirebaseAuth.instance.currentUser?.uid;

  // ฟังก์ชันดึง PromptPay ID จาก Firestore
  Future<String> getPromptPayId() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('settings')
          .doc('promptpayID') // ID ของเอกสาร settings
          .get();
      return doc['id']; // คืนค่า PromptPay ID
    } catch (e) {
      throw Exception('Error fetching PromptPay ID: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentsForPatient(
      String patientId, String statusFilter) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Appointments')
          .where('patient_id', isEqualTo: patientId)
          .where('status', isEqualTo: statusFilter)
          .get();

      List<Map<String, dynamic>> result = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // ดึง user_id ของแพทย์จาก Doctors collection
        DocumentSnapshot doctorSnapshot =
            await _firestore.collection('Doctors').doc(data['doctor_id']).get();
        String userId = doctorSnapshot.get('user_id');

        // ดึงชื่อแพทย์จาก User collection
        DocumentSnapshot userSnapshot =
            await _firestore.collection('User').doc(userId).get();
        String doctorName =
            '${userSnapshot.get('first_name')} ${userSnapshot.get('last_name')}';

        result.add({
          'appointment_id': doc.id,
          'appointment_date': data['appointment_date'],
          'appointment_time': data['appointment_time'],
          'doctor_name': doctorName,
          'amount': data['payment_amount'],
          'status': data['status'],
          'promptPayId': data['promptPayId'], // เพิ่ม promptPayId
        });
      }

      return result;
    } catch (e) {
      throw Exception('Error fetching payments for patient: $e');
    }
  }

  //ฟังก์ชันสำหรับผู้ใช้อัปโหลดสลิป
  Future<void> uploadSlip(BuildContext context, String appointmentId) async {
    try {
      final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedImage == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กำลังอัปโหลดสลิป...')),
      );

      File slipImage = File(pickedImage.path);
      final storageRef =
          _storage.ref().child('payment_slips/$appointmentId.jpg');
      await storageRef.putFile(slipImage);
      final slipUrl = await storageRef.getDownloadURL();

      // ✅ อัปเดตสถานะใน Firestore ก่อน (สำคัญที่สุด)
      await _firestore.collection('Appointments').doc(appointmentId).update({
        'payment_slip_url': slipUrl,
        'payment_status': 'รอตรวจสอบ',
      });

      // ✅ ดึง Patient ID และชื่อผู้ป่วย
      final patientId = FirebaseAuth.instance.currentUser?.uid;
      if (patientId == null)
        throw Exception('❌ ไม่พบข้อมูลผู้ป่วย (Patient ID)');

      DocumentSnapshot patientSnapshot =
          await _firestore.collection('User').doc(patientId).get();
      String patientName = patientSnapshot['first_name'] ?? 'ไม่ทราบชื่อ';

      // ✅ เรียก Background task (ไม่ await)
      unawaited(_notifyStaffAboutSlipUploadBackground(
          appointmentId, patientId, patientName, slipUrl));

      // ✅ แจ้งผู้ใช้งานทันที (ไม่ต้องรอแจ้งเตือน)
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ อัปโหลดสลิปสำเร็จ และแจ้งเจ้าหน้าที่เรียบร้อย'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
      rethrow;
    }
  }

  Future<void> _notifyStaffAboutSlipUploadBackground(String appointmentId,
      String patientId, String patientName, String slipUrl) async {
    try {
      // ✅ แจ้ง Backend ให้ส่ง Notification ถึงเจ้าหน้าที่ (ไม่ await)
      unawaited(http.post(
        Uri.parse('${AppConfig.apiUrl}/notify-staff-payment-upload'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'appointment_id': appointmentId,
          'patient_id': patientId,
          'slip_url': slipUrl,
        }),
      ));

      // ✅ ดึงอีเมลของ Staff จาก Firestore (ไม่จำเป็นต้องรอที่ UI)
      QuerySnapshot staffSnapshot = await _firestore
          .collection('User')
          .where('role', isEqualTo: 'Staff')
          .limit(1)
          .get();

      if (staffSnapshot.docs.isNotEmpty) {
        String staffEmail = staffSnapshot.docs.first['email'];

        String emailSubject = '💳 แจ้งเตือน: ผู้ป่วยอัปโหลดสลิปชำระเงิน';
        String emailBody = 'เรียนเจ้าหน้าที่,\n\n'
            'ผู้ป่วยชื่อ **$patientName** ได้ทำการชำระเงินและอัปโหลดสลิปเรียบร้อยแล้ว.\n\n'
            '📎 ดูสลิปที่แนบมา: [คลิกที่นี่]($slipUrl)\n\n'
            'กรุณาตรวจสอบและอัปเดตสถานะการชำระเงินในระบบ MediBridge.\n\n'
            'ขอบคุณครับ/ค่ะ\nMediBridge Team';

        unawaited(NotificationService.instance.sendEmailNotification(
          toEmail: staffEmail,
          subject: emailSubject,
          body: emailBody,
        ));

        debugPrint('✅ (Background) ส่งอีเมลแจ้งเตือนให้ Staff สำเร็จ');
      } else {
        debugPrint('❌ (Background) ไม่พบอีเมลของ Staff ในระบบ');
      }
    } catch (e) {
      debugPrint('❌ (Background) Error sending notifications: $e');
    }
  }
}
