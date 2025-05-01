import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medibridge_application/widgets/doc_main_layout.dart';
import '../../controllers/patient_history_controller.dart';

class PatientHistoryPage extends StatelessWidget {
  final String patientId;
  final String doctorId;
  final PatientHistoryController _controller = PatientHistoryController();

  PatientHistoryPage(
      {super.key, required this.patientId, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return DocMainLayout(
        selectedIndex: 0,
        doctorId: doctorId,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'ประวัติผู้ป่วย',
              style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: FutureBuilder<Map<String, dynamic>>(
            future: _controller.fetchPatientData(patientId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                    child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
              }
              if (!snapshot.hasData) {
                return const Center(child: Text('ไม่พบข้อมูลผู้ป่วย'));
              }

              final data = snapshot.data!;

              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        MediaQuery.of(context).size.width * 0.05, // ขอบซ้าย-ขวา
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 500,
                          minWidth: 400,
                        ),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start, // ข้อมูลชิดซ้าย
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ชื่อผู้ป่วย
                                Text(
                                  data['name'],
                                  style: GoogleFonts.prompt(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // ข้อมูลผู้ป่วย
                                buildInfoRow(
                                    'วัน/เดือน/ปีเกิด:',
                                    _controller.calculateAgeWithDate(
                                        data['date_of_birth'] ?? '')),
                                buildInfoRow('เพศ:', data['gender']),
                                buildInfoRow('กรุ๊ปเลือด:', data['blood_type']),
                                buildInfoRow(
                                    'ประวัติการแพ้:', data['allergies']),
                                buildInfoRow(
                                    'โรคประจำตัว:', data['chronic_conditions']),
                                buildInfoRow(
                                    'น้ำหนัก:', '${data['weight']} kg'),
                                buildInfoRow(
                                    'ส่วนสูง:', '${data['height']} cm'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // ใต้ ConstrainedBox (การ์ดข้อมูลผู้ป่วย) เพิ่มตรงนี้เลย
                      const SizedBox(height: 20), // เพิ่มระยะห่าง
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _controller.fetchAppointmentHistory(
                            patientId), // ดึงประวัติการนัด
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                                child: Text(
                              'ไม่มีประวัติการรักษา',
                              style: GoogleFonts.prompt(color: Colors.grey),
                            ));
                          }

                          final appointments = snapshot.data!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16.0),
                                child: Text(
                                  'ประวัติการรักษา',
                                  style: GoogleFonts.prompt(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: appointments.length,
                                itemBuilder: (context, index) {
                                  final appointment = appointments[index];
                                  return buildAppointmentCard(appointment);
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ));
  }

  // ฟังก์ชันสร้าง RichText (หัวข้อ: ตัวหนา, ข้อมูล: ตัวปกติ)
  Widget buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: title,
              style: GoogleFonts.prompt(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextSpan(
              text: ' $value',
              style: GoogleFonts.prompt(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAppointmentCard(Map<String, dynamic> appointment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // ดึงรูปจาก profile_pic
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      appointment['profile_pic'] ??
                          'https://via.placeholder.com/50', // หากไม่มีรูปให้ใช้ Placeholder
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/doctor_placeholder.png',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'วันที่นัดหมาย: ${DateFormat('d MMMM yyyy', 'th_TH').format(appointment['appointment_date'])}',
                        style: GoogleFonts.prompt(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        'นพ. ${appointment['doctor_name']}',
                        style: GoogleFonts.prompt(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              buildBoldTextRow(
                  'การวินิจฉัย:', appointment['diagnosis'] ?? 'ไม่มีข้อมูล'),
              buildBoldTextRow(
                  'การรักษา:', appointment['treatment'] ?? 'ไม่มีข้อมูล'),
              buildBoldTextRow(
                  'ยาที่สั่ง:', appointment['prescription'] ?? 'ไม่มีข้อมูล'),
            ],
          ),
        ),
      ),
    );
  }

// ฟังก์ชันช่วยให้หัวข้อเป็นตัวหนา และข้อมูลเป็นตัวปกติ
  Widget buildBoldTextRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$title ', // หัวข้อ
              style: GoogleFonts.prompt(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextSpan(
              text: value, // ข้อมูล
              style: GoogleFonts.prompt(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
