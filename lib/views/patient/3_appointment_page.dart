import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../controllers/appointment_controller.dart';

class AppointmentPage3 extends StatefulWidget {
  final Map<String, dynamic>? appointmentDetails;

  const AppointmentPage3({Key? key, required this.appointmentDetails})
      : super(key: key);

  @override
  _AppointmentPage3State createState() => _AppointmentPage3State();
}

class _AppointmentPage3State extends State<AppointmentPage3> {
  final AppointmentController _appointmentController = AppointmentController();
  bool isLoading = false; // ตัวแปรสำหรับแสดงการโหลด

  Future<void> confirmAppointment() async {
    if (isLoading) return; // ป้องกันการกดซ้ำ

    setState(() {
      isLoading = true; // เริ่มโหลด
    });

    try {
      if (widget.appointmentDetails == null) {
        throw Exception('ไม่มีข้อมูลการนัดหมาย');
      }

      final appointmentDateRaw = widget.appointmentDetails!['appointment_date'];
      DateTime appointmentDate;

      if (appointmentDateRaw is String) {
        appointmentDate = DateFormat('dd/MM/yyyy').parse(appointmentDateRaw);
      } else if (appointmentDateRaw is Timestamp) {
        appointmentDate = appointmentDateRaw.toDate();
      } else {
        throw Exception('รูปแบบวันที่ไม่ถูกต้อง');
      }

      final isAvailable = await _appointmentController.isTimeSlotAvailable(
        doctorId: widget.appointmentDetails!['doctor_id'],
        date: appointmentDate,
        time: widget.appointmentDetails!['appointment_time'],
      );

      if (isAvailable) {
        await _appointmentController.confirmAppointmentFromPatient(
          patientId: widget.appointmentDetails!['patient_id'],
          doctorId: widget.appointmentDetails!['doctor_id'],
          appointmentDate: appointmentDate,
          appointmentTime: widget.appointmentDetails!['appointment_time'],
        );

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'สำเร็จ',
                style: GoogleFonts.prompt(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
              content: Text('การนัดหมายสำเร็จ', style: GoogleFonts.prompt()),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/patientHome');
                  },
                  child: Text('ตกลง',
                      style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'ข้อผิดพลาด',
                style: GoogleFonts.prompt(
                    fontWeight: FontWeight.bold, color: Colors.red[900]),
              ),
              content:
                  Text('เวลานี้ไม่ว่าง กรุณาเลือกเวลาอื่น', style: GoogleFonts.prompt()),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('ตกลง',
                      style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('ข้อผิดพลาด',
                style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
            content: Text('เกิดข้อผิดพลาด: $e', style: GoogleFonts.prompt()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('ตกลง',
                    style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        isLoading = false; // หยุดโหลดเมื่อทำงานเสร็จ
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentDetails = widget.appointmentDetails;

    if (appointmentDetails == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'นัดหมายแพทย์',
            style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Text(
            'ไม่พบข้อมูลการนัดหมาย',
            style: GoogleFonts.prompt(
                fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'นัดหมายแพทย์',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ตรวจสอบการนัดหมาย',
              style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 20),

            // แสดงรายละเอียดการนัดหมาย
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                'วัน/เดือน/ปี',
                style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${appointmentDetails['appointment_date']}',
                style: GoogleFonts.prompt(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(
                'เวลา',
                style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${appointmentDetails['appointment_time']} น.',
                style: GoogleFonts.prompt(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(
                'แพทย์',
                style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'นพ. ${appointmentDetails['doctor_name']} สาขา: ${appointmentDetails['specialization']}',
                style: GoogleFonts.prompt(),
              ),
            ),
            const SizedBox(height: 40),

            // ปุ่มยืนยัน
            Center(
              child: ElevatedButton(
                onPressed: isLoading ? null : confirmAppointment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                  backgroundColor: const Color(0xFF3B83F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 3,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'ยืนยัน',
                        style: GoogleFonts.prompt(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
