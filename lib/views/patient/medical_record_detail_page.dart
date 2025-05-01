import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medibridge_application/services/medical_record_service.dart';

class PatientMedicalRecordDetailPage extends StatelessWidget {
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final Map<String, dynamic> record;
  final MedicalRecordService _medicalRecordService = MedicalRecordService();

  PatientMedicalRecordDetailPage({
    super.key,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ แปลงวันที่เป็น "30 ธันวาคม 2023"
    String formattedDate = "ไม่ระบุวันที่";
    if (record['appointment_date'] != null) {
      if (record['appointment_date'] is Timestamp) {
        formattedDate = DateFormat('d MMMM yyyy', 'th')
            .format((record['appointment_date'] as Timestamp).toDate());
      } else {
        formattedDate = DateFormat('d MMMM yyyy', 'th')
            .format(DateTime.parse(record['appointment_date'].toString()));
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "รายละเอียดประวัติการรักษา",
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 วันที่นัดหมาย
            _buildInfoCard(
              icon: Icons.calendar_today,
              title: "วันนัดหมาย",
              value: formattedDate,
              iconColor: Colors.blue,
            ),
            const SizedBox(height: 12),

            // 🔹 ข้อมูลแพทย์
            FutureBuilder<Map<String, String>>(
              future: _medicalRecordService.getDoctorInfo(doctorId),
              builder: (context, snapshot) {
                String doctorName =
                    record['doctor_name'] ?? snapshot.data?['name'] ?? 'ไม่พบข้อมูลแพทย์';
                String doctorImage = snapshot.data?['profile_pic'] ?? '';

                return _buildDoctorCard(doctorName, doctorImage);
              },
            ),
            const SizedBox(height: 16),

            // 🔹 การวินิจฉัย + การรักษา (รวมกันในกรอบเดียว)
            _buildDiagnosisAndTreatment(
                record['diagnosis'] ?? 'ไม่มีข้อมูล', record['treatment'] ?? 'ไม่มีข้อมูล'),
            const SizedBox(height: 12),

            // 🔹 รายการยา
            _buildMedicineSection(record['prescription']),
          ],
        ),
      ),
    );
  }

  // ✅ การ์ดข้อมูลทั่วไป
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color iconColor = Colors.black,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ การ์ดแพทย์
  Widget _buildDoctorCard(String doctorName, String doctorImage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundImage: doctorImage.isNotEmpty ? NetworkImage(doctorImage) : null,
            backgroundColor: Colors.grey[300],
            child: doctorImage.isEmpty
                ? const Icon(Icons.person, size: 35, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                  "แพทย์ผู้ดูแล",
                  style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  doctorName,
                  style: GoogleFonts.prompt(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ การวินิจฉัย + การรักษา (รวมกันในกรอบเดียว)
  Widget _buildDiagnosisAndTreatment(String diagnosis, String treatment) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            "การวินิจฉัยและการรักษา",
            style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            diagnosis,
            style: GoogleFonts.prompt(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            treatment,
            style: GoogleFonts.prompt(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // ✅ รายการยา
  Widget _buildMedicineSection(List<dynamic>? prescriptions) {
    if (prescriptions == null || prescriptions.isEmpty) {
      return _buildDiagnosisAndTreatment("ยาที่สั่ง", "ไม่มีข้อมูล");
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            "ยาที่สั่ง",
            style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Column(
            children: prescriptions.map((med) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: const Icon(Icons.medication_rounded, color: Colors.blue),
                  title: Text(
                    med['name'] ?? 'ไม่ระบุชื่อยา',
                    style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                      "${med['quantity']} - ${med['frequency']}",style: GoogleFonts.prompt(),),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
