import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medibridge_application/widgets/staff_main_layout.dart';
import './../../services/appointment_service.dart';

class ManageAppointmentPage extends StatefulWidget {
  const ManageAppointmentPage({Key? key}) : super(key: key);

  @override
  _ManageAppointmentPageState createState() => _ManageAppointmentPageState();
}

class _ManageAppointmentPageState extends State<ManageAppointmentPage> {
  final AppointmentService _appointmentService = AppointmentService();

  String _selectedStatus = 'รอยืนยัน';
  late Future<List<Map<String, dynamic>>> _appointmentsFuture;

  final List<String> _statusOptions = [
    'รอยืนยัน',
    'รอชำระเงิน',
    'ยืนยันแล้ว',
    'ยกเลิก'
  ];

  @override
  void initState() {
    super.initState();
    _loadAppointmentsByStatus();
  }

  void _loadAppointmentsByStatus() {
    setState(() {
      _appointmentsFuture =
          _appointmentService.getAppointmentsByStatus(_selectedStatus);
    });

    _appointmentsFuture.then((appointments) {
      debugPrint('Appointments loaded: $appointments');
    }).catchError((error) {
      debugPrint('Error loading appointments: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return StaffMainLayout(
      selectedIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'การนัดหมาย',
            style:
                GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButton<String>(
                value: _selectedStatus,
                isExpanded: true,
                items: _statusOptions.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child:
                        Text(status, style: GoogleFonts.prompt(fontSize: 16)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                      _loadAppointmentsByStatus();
                    });
                  }
                },
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _loadAppointmentsByStatus();
                  // รอให้ Future เสร็จสิ้น (อาจใช้ await _appointmentsFuture)
                  await _appointmentsFuture;
                },
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _appointmentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListView.builder(
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          // Skeleton Placeholder
                          return Card(
                            margin: const EdgeInsets.all(25.0),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              side: const BorderSide(
                                  color: Colors.blue, width: 1.5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                      width: 120,
                                      height: 20,
                                      color: Colors.grey[300]),
                                  const SizedBox(height: 8),
                                  Container(
                                      width: 100,
                                      height: 16,
                                      color: Colors.grey[300]),
                                  const SizedBox(height: 4),
                                  Container(
                                      width: 150,
                                      height: 16,
                                      color: Colors.grey[300]),
                                  const SizedBox(height: 4),
                                  Container(
                                      width: 80,
                                      height: 16,
                                      color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                          width: 80,
                                          height: 30,
                                          color: Colors.grey[300]),
                                      Container(
                                          width: 80,
                                          height: 30,
                                          color: Colors.grey[300]),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'ไม่มีนัดหมายในสถานะ "${_selectedStatus}"',
                          style: GoogleFonts.prompt(
                              fontSize: 16, color: Colors.blueGrey),
                        ),
                      );
                    }
                    final appointments = snapshot.data!;
                    return ListView.builder(
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        var appointment = appointments[index];
                        var patientName = appointment['patient_name'];
                        var doctorName = appointment['doctor_name'];
                        var appointmentDate = appointment['appointment_date'];
                        var appointmentTime = appointment['appointment_time'];
                        return Card(
                          margin: const EdgeInsets.all(25.0),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            side: const BorderSide(
                                color: Colors.blue, width: 1.5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patientName ?? 'ไม่ทราบชื่อผู้ป่วย',
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
                                Text(
                                  'วันที่: $appointmentDate',
                                  style: GoogleFonts.prompt(
                                      fontSize: 16, color: Colors.black),
                                ),
                                Text(
                                  'เวลา: $appointmentTime',
                                  style: GoogleFonts.prompt(
                                      fontSize: 16, color: Colors.black),
                                ),
                                const SizedBox(height: 16),
                                if (_selectedStatus == 'รอยืนยัน') ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {
                                          _showConfirmationDialog(
                                              context,
                                              'ยืนยันการยกเลิกนัดหมาย',
                                              'คุณต้องการยกเลิกนัดหมายนี้ใช่หรือไม่?',
                                              appointment['appointment_id'],
                                              'ยกเลิก',
                                              appointment);
                                        },
                                        child: Text(
                                          'แพทย์ไม่ว่าง',
                                          style: GoogleFonts.prompt(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          _showConfirmationDialog(
                                              context,
                                              'ยืนยันการนัดหมาย',
                                              'คุณต้องการยืนยันนัดหมายนี้ใช่หรือไม่?',
                                              appointment['appointment_id'],
                                              'รอชำระเงิน',
                                              appointment);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 45, vertical: 10),
                                          backgroundColor:
                                              const Color(0xFF3B83F6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                        ),
                                        child: Text(
                                          'ยืนยัน',
                                          style: GoogleFonts.prompt(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (_selectedStatus == 'รอชำระเงิน') ...[
                                  Center(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        _showConfirmationDialog(
                                            context,
                                            'ยืนยันการยกเลิกนัดหมาย',
                                            'คุณต้องการยกเลิกนัดหมายนี้ใช่หรือไม่?',
                                            appointment['appointment_id'],
                                            'ยกเลิก',
                                            appointment);
                                      },
                                      child: Text(
                                        'แพทย์ไม่ว่าง',
                                        style: GoogleFonts.prompt(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// เปลี่ยน _showConfirmationDialog ใน onPressed ของปุ่ม "ยืนยัน"
  Future<void> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    String appointmentId,
    String action,
    Map<String, dynamic> appointment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title,
              style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
          content: Text(message, style: GoogleFonts.prompt()),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('ยืนยัน'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _appointmentService.updateAppointmentAndNotify(
                  appointment['appointment_id'],
                  action, // 'รอชำระเงิน' หรือ 'ยกเลิก'
                  appointment,
                );
                // หลังจากอัปเดตแล้ว ให้รีโหลดข้อมูลใหม่
                _loadAppointmentsByStatus();
              },
            ),
          ],
        );
      },
    );
  }
}
