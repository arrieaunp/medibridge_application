import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medibridge_application/models/prescription_model.dart';

class MedicalRecordModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String appointmentId;
  final String diagnosis;
  final String treatment;
  final List<PrescriptionModel> prescriptions;
  final DateTime recordDate;

  MedicalRecordModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.appointmentId,
    required this.diagnosis,
    required this.treatment,
    required this.prescriptions,
    required this.recordDate,
  });

  // ✅ ฟังก์ชันแปลงจาก Firestore -> MedicalRecordModel
  factory MedicalRecordModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return MedicalRecordModel(
      id: doc.id,
      appointmentId: data['appointment_id'] ?? '',
      patientId: data['patient_id'] ?? '',
      doctorId: data['doctor_id'] ?? '',
      diagnosis: data['diagnosis'] ?? '',
      treatment: data['treatment'] ?? '',
      recordDate: (data['date'] as Timestamp).toDate(),

      // 🔥 ตรวจสอบว่า prescription ถูกโหลดมาหรือไม่
      prescriptions: (data['prescription'] as List<dynamic>?)
              ?.map((e) => PrescriptionModel.fromMap(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patient_id': patientId,
      'doctor_id': doctorId,
      'appointment_id': appointmentId,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'prescription': prescriptions.map((presc) => presc.toMap()).toList(),
      'date': recordDate,
    };
  }
}
