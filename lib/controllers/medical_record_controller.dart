import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:medibridge_application/models/medical_record_model.dart';
import 'package:medibridge_application/models/prescription_model.dart';
import 'package:medibridge_application/services/medical_record_service.dart';

class MedicalRecordController extends ChangeNotifier {
  final MedicalRecordService _service = MedicalRecordService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MedicalRecordService _medicalRecordService = MedicalRecordService();
  List<Map<String, dynamic>> medicalHistory = [];
  bool isLoading = false;

  Future<List<Map<String, dynamic>>> fetchPatientsList(String doctorId) {
    return _service.fetchPatientsList(doctorId);
  }

  Future<List<Map<String, dynamic>>> fetchPatientAppointments(
      String patientId, String doctorId) {
    return _service.fetchPatientAppointments(patientId, doctorId);
  }

  Future<MedicalRecordModel?> fetchMedicalRecord(String appointmentId) {
    return _service.fetchMedicalRecord(appointmentId);
  }

  Future<void> updateMedicalRecord(
      String appointmentId, MedicalRecordModel record) {
    return _service.updateMedicalRecord(appointmentId, record);
  }

  Future<Map<String, dynamic>> fetchPatientInfo(String patientId) {
    return _service.fetchPatientInfo(patientId);
  }

  // ✅ บันทึกข้อมูล Medical Record ตามปกติ
  Future<void> saveMedicalRecord(MedicalRecordModel record) async {
    try {
      await _firestore
          .collection('MedicalRecords')
          .doc(record.id)
          .set(record.toFirestore(), SetOptions(merge: true));
      debugPrint("✅ อัปเดตข้อมูล MedicalRecord สำเร็จ");
    } catch (e) {
      debugPrint("❌ Error updating MedicalRecord: $e");
    }
  }

  // ✅ เพิ่มยาเข้าไปใน prescription ของ Appointment
  Future<void> addPrescriptionToAppointment(
      String appointmentId, PrescriptionModel prescription) async {
    try {
      DocumentReference appointmentRef =
          _firestore.collection('MedicalRecords').doc(appointmentId);

      // อ่านข้อมูล prescription เดิมจาก Firestore
      DocumentSnapshot doc = await appointmentRef.get();
      List<dynamic> existingPrescriptions =
          (doc.data() as Map<String, dynamic>)['prescription'] ?? [];

      // เพิ่ม prescription ใหม่เข้าไปใน array
      existingPrescriptions.add(prescription.toMap());

      // อัปเดตเอกสาร Firestore
      await appointmentRef.update({
        'prescription': existingPrescriptions,
      });

      debugPrint("✅ เพิ่มยาเข้าไปใน MedicalRecord สำเร็จ");
    } catch (e) {
      debugPrint("❌ Error adding prescription to MedicalRecord: $e");
    }
  }

  Future<void> removePrescriptionFromFirestore(
      String appointmentId, PrescriptionModel prescription) async {
    try {
      DocumentReference appointmentRef =
          _firestore.collection('MedicalRecords').doc(appointmentId);

      // ลบค่าที่ยาตรงกับ prescription ออกจาก array
      await appointmentRef.update({
        'prescription': FieldValue.arrayRemove([prescription.toMap()])
      });

      debugPrint("✅ ลบยาออกจาก Firestore สำเร็จ");
    } catch (e) {
      debugPrint("❌ Error deleting prescription from Firestore: $e");
    }
  }

  Future<void> fetchMedicalHistory() async {
    isLoading = true;
    notifyListeners();

    medicalHistory = await _medicalRecordService.getMedicalHistory();

    isLoading = false;
    notifyListeners();
  }

  // ✅ ถ้า `selectedDate` เป็น null ให้ดึงนัดหมายล่าสุด
  Future<void> fetchMedicalHistoryByDate(DateTime? selectedDate) async {
    isLoading = true;
    notifyListeners();

    if (selectedDate == null) {
      medicalHistory = await _medicalRecordService.getMedicalHistory();
    } else {
      medicalHistory =
          await _medicalRecordService.getMedicalHistoryByDate(selectedDate);
    }

    isLoading = false;
    notifyListeners();
  }
}
