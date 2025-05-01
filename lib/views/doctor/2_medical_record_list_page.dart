import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medibridge_application/controllers/medical_record_controller.dart';
import 'package:medibridge_application/widgets/doc_main_layout.dart';

class PatientAppointmentListPage extends StatefulWidget {
  final String patientId;
  final String doctorId;
  const PatientAppointmentListPage(
      {Key? key, required this.patientId, required this.doctorId})
      : super(key: key);

  @override
  _PatientAppointmentListPageState createState() =>
      _PatientAppointmentListPageState();
}

class _PatientAppointmentListPageState
    extends State<PatientAppointmentListPage> {
  final MedicalRecordController controller = MedicalRecordController();
  late Future<List<Map<String, dynamic>>> fetchAppointmentsFuture;

  @override
  void initState() {
    super.initState();
    fetchAppointmentsFuture =
        controller.fetchPatientAppointments(widget.patientId, widget.doctorId);
  }

  @override
  Widget build(BuildContext context) {
    final args =
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ??
            {};

    return DocMainLayout(
        selectedIndex: 0,
        doctorId: widget.doctorId,
        child: Scaffold(
            appBar: AppBar(
              title: Text(
                'นัดหมายย้อนหลัง',
                style: GoogleFonts.prompt(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                // เรียก setState เพื่อกำหนด Future ใหม่
                setState(() {
                  fetchAppointmentsFuture = controller.fetchPatientAppointments(
                    widget.patientId,
                    widget.doctorId,
                  );
                });
                // รอให้ Future ทำงานเสร็จ (optional)
                await fetchAppointmentsFuture;
              },
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchAppointmentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError ||
                      snapshot.data == null ||
                      snapshot.data!.isEmpty) {
                    return const Center(child: Text('ไม่มีนัดหมายย้อนหลัง'));
                  }

                  final appointments = snapshot.data!;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      final appointment = appointments[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: ListTile(
                          title: Text(
                            appointment['date'],
                            style: GoogleFonts.prompt(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'วินิจฉัย: ${appointment['diagnosis'] ?? 'ไม่ระบุ'}',
                            style: GoogleFonts.prompt(fontSize: 14),
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B83F6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              print(
                                  "📌 ส่งค่าไปหน้า MedicalRecordDetailPage: ${appointment['appointment_id']}");
                              Navigator.pushNamed(
                                context,
                                '/patientMedicalRecord',
                                arguments: {
                                  'appointmentId':
                                      appointment['appointment_id'],
                                  'patientId':
                                      args['patientId'] ?? '', // ✅ ป้องกัน null
                                },
                              );
                            },
                            child: Text(
                              'ดูรายละเอียด',
                              style: GoogleFonts.prompt(color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )));
  }
}
