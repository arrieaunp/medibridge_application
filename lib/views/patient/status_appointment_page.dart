import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medibridge_application/widgets/main_layout.dart';
import '../../controllers/appointment_controller.dart';

class StatusAppointmentPage extends StatefulWidget {
  final String
      patientId; // รับ patientId มาเพื่อดึงข้อมูลการนัดหมายที่เกี่ยวข้อง

  const StatusAppointmentPage({Key? key, required this.patientId})
      : super(key: key);

  @override
  _StatusAppointmentPageState createState() => _StatusAppointmentPageState();
}

class _StatusAppointmentPageState extends State<StatusAppointmentPage>
    with SingleTickerProviderStateMixin {
  final AppointmentController _appointmentController = AppointmentController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
        selectedIndex: 1,
        child: Scaffold(
            appBar: AppBar(
              title: Text(
                'สถานะการนัดหมาย',
                style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Text(
                      'กำลังมาถึง',
                      style: GoogleFonts.prompt(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Tab(
                    child: Text(
                      'สำเร็จ',
                      style: GoogleFonts.prompt(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Tab(
                    child: Text(
                      'ยกเลิก',
                      style: GoogleFonts.prompt(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
                labelColor: const Color(0xFF3B83F6),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF3B83F6),
                labelStyle: GoogleFonts.prompt(
                    fontWeight: FontWeight.bold, fontSize: 16),
                unselectedLabelStyle: GoogleFonts.prompt(
                    fontWeight: FontWeight.w400, fontSize: 14),
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentList('กำลังมาถึง'), // ปรับเป็น 'กำลังมาถึง'
                _buildAppointmentList(
                    'ยืนยันแล้ว'), // ปรับเป็น 'สำเร็จ' (เมื่อชำระเงินเสร็จ)
                _buildAppointmentList('ยกเลิก'),
              ],
            )));
  }

  Widget _buildAppointmentList(String statusFilter) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future:
          _appointmentController.getAppointmentsForPatient(widget.patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              child: Text(
            'ไม่มีการนัดหมาย',
            style: GoogleFonts.prompt(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
          ));
        } else {
          // กรองสถานะที่จะแสดงในแต่ละแท็บ
          final appointments = snapshot.data!
    .where((appointment) =>
        statusFilter == 'กำลังมาถึง'
            ? (appointment['status'] == 'รอยืนยัน' ||
                appointment['status'] == 'รอชำระเงิน')
            : appointment['status'] == statusFilter)
    .toList();


          if (appointments.isEmpty) {
            return  Center(child: Text('ไม่มีการนัดหมายในหมวดนี้',style: GoogleFonts.prompt(fontSize: 16,color: Colors.grey),));
          }

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];

              if (appointment['appointment_date'] == null ||
                  appointment['appointment_time'] == null ||
                  appointment['doctor_id'] == null) {
                return const SizedBox.shrink();
              }

              return FutureBuilder<Map<String, dynamic>?>(
                future: _appointmentController
                    .getDoctorDetails(appointment['doctor_id']),
                builder: (context, doctorSnapshot) {
                  if (doctorSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (doctorSnapshot.hasError) {
                    return const Center(
                        child: Text('เกิดข้อผิดพลาดในการดึงข้อมูลแพทย์'));
                  } else if (!doctorSnapshot.hasData) {
                    return const SizedBox.shrink();
                  } else {
                    final doctor = doctorSnapshot.data!;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                              DateFormat('dd MMMM yyyy').format(
                                  (appointment['appointment_date'] as Timestamp)
                                      .toDate()),
                              style: GoogleFonts.prompt(
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${appointment['appointment_time']} น.\nแพทย์: ${doctor['first_name']} ${doctor['last_name']}',
                              style: GoogleFonts.prompt(),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  appointment['status'] == 'รอยืนยัน' ||
                                          appointment['status'] == 'รอชำระเงิน'
                                      ? Icons.hourglass_empty
                                      : appointment['status'] == 'ยกเลิก'
                                          ? Icons.cancel
                                          : Icons.check_circle,
                                  color: appointment['status'] == 'ยกเลิก'
                                      ? Colors.red
                                      : appointment['status'] == 'รอชำระเงิน'
                                          ? Colors.orange
                                          : Colors.green,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  appointment['status'] ?? 'ไม่ทราบสถานะ',
                                  style: GoogleFonts.prompt(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (appointment['status'] == 'รอยืนยัน')
                            TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                        'ยกเลิกการนัดหมาย',
                                        style: GoogleFonts.prompt(),
                                      ),
                                      content: Text(
                                        'คุณต้องการยกเลิกการนัดหมายนี้จริงๆ ใช่หรือไม่?',
                                        style: GoogleFonts.prompt(),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(
                                            'ไม่ใช่',
                                            style: GoogleFonts.prompt(
                                                color: Colors.grey),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                            await _appointmentController
                                                .cancelAppointment(appointment[
                                                    'appointment_id']);
                                            setState(() {});
                                          },
                                          child: Text(
                                            'ใช่',
                                            style: GoogleFonts.prompt(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text(
                                'ยกเลิกนัดหมาย',
                                style: GoogleFonts.prompt(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }
                },
              );
            },
          );
        }
      },
    );
  }
}
