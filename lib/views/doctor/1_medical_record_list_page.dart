import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medibridge_application/controllers/medical_record_controller.dart';
import 'package:medibridge_application/widgets/doc_main_layout.dart';

class MedicalRecordListPage extends StatefulWidget {
  final String doctorId;

  const MedicalRecordListPage({Key? key, required this.doctorId})
      : super(key: key);

  @override
  _MedicalRecordListPageState createState() => _MedicalRecordListPageState();
}

class _MedicalRecordListPageState extends State<MedicalRecordListPage> {
  final MedicalRecordController controller = MedicalRecordController();
  late Future<List<Map<String, dynamic>>> fetchPatientsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchPatientsFuture = controller.fetchPatientsList(widget.doctorId);
  }

  @override
  Widget build(BuildContext context) {
    return DocMainLayout(
      selectedIndex: 0,
      doctorId: widget.doctorId,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'ประวัติการรักษา',
            style: GoogleFonts.prompt(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchPatientsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError ||
                snapshot.data == null ||
                snapshot.data!.isEmpty) {
              return const Center(child: Text('ไม่มีประวัติการรักษา'));
            }

            final patients = snapshot.data!;

            // กรองรายชื่อผู้ป่วยตามคำค้นหา (ไม่คำนึงถึงตัวพิมพ์ใหญ่-เล็ก)
            final filteredPatients = patients.where((patient) {
              final fullName = patient['full_name'] ?? '';
              return fullName.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // ช่องค้นหา
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ค้นหาชื่อผู้ป่วย',
                      hintStyle: GoogleFonts.prompt(),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // รายชื่อผู้ป่วยที่ค้นหา (กรองแล้ว)
                  Expanded(
                    child: filteredPatients.isNotEmpty
                        ? ListView.builder(
                            itemCount: filteredPatients.length,
                            itemBuilder: (context, index) {
                              final patient = filteredPatients[index];
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                                child: ListTile(
                                  title: Text(
                                    patient['full_name'],
                                    style: GoogleFonts.prompt(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'อายุ ${patient['age']} ปี   เพศ ${patient['gender']}',
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
                                      Navigator.pushNamed(
                                        context,
                                        '/patientAppointments',
                                        arguments: {
                                          'doctorId': widget.doctorId,  // ตรวจสอบว่า doctorId มีค่า
                                          'patientId': patient['patient_id'],
                                          'patientName': patient['full_name'],
                                          'patientAge': patient['age'],
                                          'patientGender': patient['gender'],
                                          'patientAllergies':
                                              patient['allergies'] ?? 'ไม่มีข้อมูล',
                                          'patientChronicDiseases':
                                              patient['chronic_diseases'] ?? 'ไม่มีข้อมูล',
                                        },
                                      );
                                    },
                                    child: Text(
                                      'เพิ่มเติม',
                                      style: GoogleFonts.prompt(
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              'ไม่พบผู้ป่วยที่ค้นหา',
                              style: GoogleFonts.prompt(
                                  fontSize: 16, color: Colors.grey),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
