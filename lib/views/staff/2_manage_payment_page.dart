import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medibridge_application/controllers/appointment_controller.dart';
import 'package:provider/provider.dart';

class ManagePaymentPage2 extends StatefulWidget {
  final String appointmentId;

  const ManagePaymentPage2({Key? key, required this.appointmentId})
      : super(key: key);

  @override
  _ManagePaymentPage2State createState() => _ManagePaymentPage2State();
}

class _ManagePaymentPage2State extends State<ManagePaymentPage2> {
  bool _isSaving = false; // ✅ ตัวแปรควบคุมสถานะ Loading ของปุ่มบันทึก

  @override
  Widget build(BuildContext context) {
    final appointmentController =
        Provider.of<AppointmentController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'เพิ่มรายการชำระเงิน',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder(
        future: appointmentController.fetchPaymentDetails(widget.appointmentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('ไม่พบข้อมูลการชำระเงิน'),
            );
          }

          final data = snapshot.data as Map<String, dynamic>;

          if (data.containsKey('payment_amount') &&
              data['payment_amount'] != null) {
            appointmentController.paymentAmountController.text =
                data['payment_amount'].toString();
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['patient_name'],
                  style: GoogleFonts.prompt(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3B83F6)),
                ),
                Text(
                  'แพทย์: ${data['doctor_name']}',
                  style: GoogleFonts.prompt(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'วันที่: ${data['appointment_date']}',
                  style: GoogleFonts.prompt(fontSize: 16),
                ),
                Text(
                  'เวลา: ${data['appointment_time']} น.',
                  style: GoogleFonts.prompt(fontSize: 16),
                ),
                const SizedBox(height: 25),
                Text(
                  'จำนวนเงิน:',
                  style: GoogleFonts.prompt(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: appointmentController.paymentAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'กรุณากรอกจำนวนเงิน',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            if (appointmentController
                                .paymentAmountController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('กรุณากรอกจำนวนเงิน')),
                              );
                              return;
                            }

                            setState(() {
                              _isSaving = true; // ✅ เริ่มการโหลด
                            });

                            try {
                              double amount = double.parse(appointmentController
                                  .paymentAmountController.text);
                              await appointmentController.savePayment(
                                  widget.appointmentId, amount);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('บันทึกสำเร็จ')),
                                );
                                Navigator.pop(
                                    context, true); // ✅ ส่งค่า true กลับไป
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setState(() {
                                  _isSaving = false; // ✅ หยุดการโหลด
                                });
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B83F6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 45, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'บันทึก',
                            style: GoogleFonts.prompt(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
