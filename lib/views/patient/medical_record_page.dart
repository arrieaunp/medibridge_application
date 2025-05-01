import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:medibridge_application/controllers/medical_record_controller.dart';
import 'package:medibridge_application/widgets/medical_record_card.dart';
import 'package:intl/intl.dart';

class MedicalHistoryPage extends StatefulWidget {
  @override
  _MedicalHistoryPageState createState() => _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends State<MedicalHistoryPage> {
  final TextEditingController _dateController = TextEditingController();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<MedicalRecordController>(context, listen: false)
            .fetchMedicalHistoryByDate(null)); // ✅ โหลดนัดหมายล่าสุด
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });

      Provider.of<MedicalRecordController>(context, listen: false)
          .fetchMedicalHistoryByDate(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MedicalRecordController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "ประวัติการรักษา",
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: "เลือกวันเดือนปีที่ต้องการค้นหา",
                hintStyle: GoogleFonts.prompt(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : controller.medicalHistory.isEmpty
                      ? Center(
                          child: Text("ไม่มีประวัติการรักษา",
                              style: GoogleFonts.prompt()))
                      : ListView.builder(
                          itemCount: controller.medicalHistory.length,
                          itemBuilder: (context, index) {
                            var record = controller.medicalHistory[index];

                            // ✅ แปลง appointment_date ให้ถูกต้องก่อนใช้
                            String formattedDate = "ไม่ระบุวันที่";
                            if (record['appointment_date'] != null) {
                              if (record['appointment_date'] is Timestamp) {
                                formattedDate = DateFormat('d MMMM yyyy')
                                    .format((record['appointment_date']
                                            as Timestamp)
                                        .toDate());
                              } else if (record['appointment_date']
                                  is DateTime) {
                                formattedDate = DateFormat('d MMMM yyyy')
                                    .format(record['appointment_date']);
                              }
                            }

                            return MedicalRecordCard(
                              doctorName: record['doctor_name'],
                              doctorProfilePic:
                                  record['doctor_profile_pic'] ?? '',
                              treatmentDate:
                                  formattedDate, // ✅ ใช้วันที่ที่แปลงแล้ว
                              diagnosis: record['diagnosis'] ?? 'ไม่มีข้อมูล',
                              onTap: () {
                                print(
                                    "✅ Debug: Going to MedicalRecordDetailPage");
                                print(
                                    "➡️ appointmentId: ${record['appointment_id']}");
                                print("➡️ patientId: ${record['patient_id']}");
                                print("➡️ doctorId: ${record['doctor_id']}");

                                Navigator.pushNamed(
                                  context,
                                  '/medicalRecordDetail', // ✅ ต้องตรงกับที่ลงทะเบียนใน `main.dart`
                                  arguments: {
                                    'appointmentId':
                                        record['appointment_id'] ?? '',
                                    'patientId': record['patient_id'] ?? '',
                                    'doctorId': record['doctor_id'] ?? '',
                                    'record': record,
                                  },
                                );
                              },
                              onFeedbackPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/feedback',
                                  arguments: {
                                    'doctorId': record['doctor_id'] ?? '',
                                    'appointmentId':
                                        record['appointment_id'] ?? '',
                                  },
                                );
                              },
                            );
                          },
                        ),
            )
          ],
        ),
      ),
    );
  }
}
