import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medibridge_application/models/appointment_model.dart';
import 'package:medibridge_application/services/appointment_service.dart';
import 'package:medibridge_application/views/staff/check_slip_page.dart';

class ManagePaymentPage extends StatefulWidget {
  const ManagePaymentPage({Key? key}) : super(key: key);

  @override
  _ManagePaymentPageState createState() => _ManagePaymentPageState();
}

class _ManagePaymentPageState extends State<ManagePaymentPage> {
  final AppointmentService _appointmentService = AppointmentService();
  late Future<List<Map<String, dynamic>>> _appointmentsFuture;
  String _selectedStatus = 'รอเพิ่มรายการชำระเงิน'; // สถานะที่เลือกเริ่มต้น
  final List<String> _statusOptions = [
    'รอเพิ่มรายการชำระเงิน',
    'รอการชำระเงิน',
    'รอตรวจสอบ',
    'ชำระเงินสำเร็จ',
  ];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAppointmentsByStatus(_selectedStatus);
  }

  void _fetchAppointmentsByStatus(String status) {
    setState(() {
      _appointmentsFuture =
          _appointmentService.getAppointmentsByPaymentStatus(status);
    });
  }

  // Widget สำหรับ Skeleton Card แสดงเป็นโครงรายการชำระเงิน
  Widget _buildSkeletonCard() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(color: Colors.blue, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder สำหรับชื่อผู้ป่วย
            Container(
              width: 150,
              height: 20,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            // Placeholder สำหรับชื่อแพทย์
            Container(
              width: 120,
              height: 16,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 4),
            // Placeholder สำหรับวันที่
            Container(
              width: 180,
              height: 16,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 4),
            // Placeholder สำหรับเวลานัดหมาย
            Container(
              width: 80,
              height: 16,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            // Placeholder สำหรับปุ่มเพิ่มรายการชำระเงิน/ตรวจสอบสลิป
            Center(
              child: Container(
                width: 140,
                height: 40,
                color: Colors.grey[300],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'รายการชำระเงิน',
          style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Dropdown สำหรับเลือกสถานะ
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'สถานะ: ',
                  style: GoogleFonts.prompt(),
                ),
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status, style: GoogleFonts.prompt()),
                    );
                  }).toList(),
                  onChanged: (newStatus) {
                    if (newStatus != null) {
                      setState(() {
                        _selectedStatus = newStatus;
                        _fetchAppointmentsByStatus(newStatus);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _appointmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // แสดง Skeleton Placeholders เมื่อกำลังโหลดข้อมูล
                  return ListView.builder(
                    itemCount: 5, // แสดง skeleton 5 รายการ
                    itemBuilder: (context, index) => _buildSkeletonCard(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'ไม่มีรายการในสถานะ "${_selectedStatus}"',
                      style: GoogleFonts.prompt(
                          fontSize: 16, color: Colors.blueGrey),
                    ),
                  );
                } else {
                  List<Map<String, dynamic>> appointments = snapshot.data!;

                  return ListView.builder(
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      var appointment = appointments[index]['appointment']
                          as AppointmentModel;
                      var patientName = appointments[index]['patient_name'];
                      var doctorName = appointments[index]['doctor_name'];

                      return Card(
                        margin: const EdgeInsets.all(16.0),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          side: const BorderSide(color: Colors.blue, width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patientName,
                                style: GoogleFonts.prompt(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF3B83F6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'แพทย์: $doctorName',
                                style: GoogleFonts.prompt(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'วันที่: ',
                                      style: GoogleFonts.prompt(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    TextSpan(
                                      text: DateFormat('dd MMMM yyyy')
                                          .format(appointment.appointmentDate),
                                      style: GoogleFonts.prompt(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'เวลา: ',
                                      style: GoogleFonts.prompt(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    TextSpan(
                                      text: appointment.appointmentTime,
                                      style: GoogleFonts.prompt(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: Builder(
                                  builder: (context) {
                                    if (_selectedStatus ==
                                            'รอเพิ่มรายการชำระเงิน' ||
                                        _selectedStatus == 'รอการชำระเงิน') {
                                      return ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () async {
                                                setState(() {
                                                  _isLoading = true;
                                                });

                                                final result =
                                                    await Navigator.pushNamed(
                                                  context,
                                                  '/paymentMethod',
                                                  arguments: {
                                                    'appointmentId': appointment.id,
                                                    'amount': 0,
                                                    'doctorName': appointment.doctorName,
                                                    'appointmentDate':
                                                        appointment.appointmentDate,
                                                    'appointmentTime':
                                                        appointment.appointmentTime,
                                                  },
                                                );

                                                if (result == true) {
                                                  _fetchAppointmentsByStatus(
                                                      _selectedStatus);
                                                }
                                                setState(() {
                                                  _isLoading = false;
                                                });
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF3B83F6),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(
                                                'เพิ่มรายการชำระเงิน',
                                                style: GoogleFonts.prompt(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      );
                                    } else if (_selectedStatus == 'รอตรวจสอบ') {
                                      return ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PaymentSlipVerificationPage(
                                                appointmentId: appointment.id,
                                                patientName: patientName,
                                                doctorName: doctorName,
                                                appointmentDate:
                                                    DateFormat('dd/MM/yyyy')
                                                        .format(
                                                            appointment.appointmentDate),
                                                appointmentTime:
                                                    appointment.appointmentTime,
                                              ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF3B83F6),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 45, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                        ),
                                        child: Text(
                                          'ตรวจสอบสลิป',
                                          style: GoogleFonts.prompt(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    } else {
                                      return const SizedBox();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
