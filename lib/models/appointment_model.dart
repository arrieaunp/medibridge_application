import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String status;
  final double? paymentAmount; // เพิ่มฟิลด์จำนวนเงิน
  final String? paymentStatus; // เพิ่มฟิลด์สถานะการชำระเงิน
  final DateTime? paymentDate; // เพิ่มฟิลด์วันที่ชำระเงิน
  final String? paymentSlipUrl;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    this.paymentAmount,
    this.paymentStatus,
    this.paymentDate,
    this.paymentSlipUrl, String? patientName,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      patientId: data['patient_id'],
      doctorId: data['doctor_id'],
      appointmentDate: (data['appointment_date'] as Timestamp).toDate(),
      appointmentTime: data['appointment_time'],
      status: data['status'],
      paymentAmount:
          data['payment_amount']?.toDouble(), // อ่านจำนวนเงินจาก Firestore
      paymentStatus:
          data['payment_status'], // อ่านสถานะการชำระเงินจาก Firestore
      paymentDate: data['payment_date'] != null
          ? (data['payment_date'] as Timestamp).toDate()
          : null,
      paymentSlipUrl: data['payment_slip_url'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patient_id': patientId,
      'doctor_id': doctorId,
      'appointment_date': appointmentDate,
      'appointment_time': appointmentTime,
      'status': status,
      'payment_amount': paymentAmount,
      'payment_status': paymentStatus,
      'payment_date': paymentDate,
      'payment_slip_url': paymentSlipUrl,
    };
  }

  // เพิ่ม getter สำหรับ doctorName, date และ time
  String get doctorName =>
      doctorId; // ใช้ doctorId แทน (ต้องดึงชื่อเต็มจาก Firestore)
  String get date => appointmentDate.toString(); // แปลงวันที่
  String get time => appointmentTime; // คืนค่าเวลา
}
