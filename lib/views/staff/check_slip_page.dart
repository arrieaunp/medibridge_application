import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medibridge_application/services/appointment_service.dart';

class PaymentSlipVerificationPage extends StatelessWidget {
  final String appointmentId;
  final String patientName;
  final String doctorName;
  final String appointmentDate;
  final String appointmentTime;

  const PaymentSlipVerificationPage({
    Key? key,
    required this.appointmentId,
    required this.patientName,
    required this.doctorName,
    required this.appointmentDate,
    required this.appointmentTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AppointmentService _appointmentService = AppointmentService();

    return Scaffold(
      backgroundColor: const Color(0xFF3B83F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'รายการชำระเงิน',
          style: GoogleFonts.prompt(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _appointmentService.getAppointmentDetails(appointmentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'เกิดข้อผิดพลาด: ${snapshot.error}',
                style: GoogleFonts.prompt(color: Colors.white),
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(
              child: Text('ไม่พบข้อมูล', style: TextStyle(color: Colors.white)),
            );
          } else {
            final data = snapshot.data!;
            final paymentSlipUrl = data['payment_slip_url'];

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (paymentSlipUrl != null)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Image.network(
                        paymentSlipUrl,
                        height: 350,
                        fit: BoxFit.contain,
                      ),
                    ),
                  const SizedBox(height: 16),
                  SafeArea(
                    child: Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).size.height *
                              0.3, // พื้นที่ที่เหลือหลังหัก 30%
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20.0),
                        ),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName.toUpperCase(),
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
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'วันที่: $appointmentDate',
                            style: GoogleFonts.prompt(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'เวลา: $appointmentTime',
                            style: GoogleFonts.prompt(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 55),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  await _appointmentService
                                      .approvePayment(appointmentId);
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32.0, vertical: 12.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                child: Text(
                                  'ยืนยัน',
                                  style: GoogleFonts.prompt(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  await _appointmentService
                                      .rejectPayment(appointmentId);
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32.0, vertical: 12.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                child: Text(
                                  'ยกเลิก',
                                  style: GoogleFonts.prompt(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
