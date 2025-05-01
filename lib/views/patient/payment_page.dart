import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:promptpay_qrcode_generate/promptpay_qrcode_generate.dart';
import '../../controllers/payment_controller.dart';

class PaymentPage extends StatefulWidget {
  final String appointmentId;
  final num? amount;

  final String doctorName;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String promptPayId;

  const PaymentPage({
    Key? key,
    required this.appointmentId,
    required this.amount,
    required this.doctorName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.promptPayId,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final PaymentController _paymentController = PaymentController();
  bool _isUploading = false;

  Future<void> _handleUploadSlip() async {
    setState(() {
      _isUploading = true;
    });

    try {
      await _paymentController.uploadSlip(context, widget.appointmentId);
    } catch (e) {
      print('เกิดข้อผิดพลาด: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double finalAmount = (widget.amount ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title:  Text('ชำระเงิน',style: GoogleFonts.prompt(fontWeight: FontWeight.bold),),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('Appointments')
            .doc(widget.appointmentId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: ${snapshot.error}'),
            );
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final paymentStatus = data?['payment_status'];

          if (paymentStatus == 'ชำระเงินสำเร็จ') {
            return const Center(
              child: Text(
                'การชำระเงินเรียบร้อยแล้ว',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            );
          }
          if (finalAmount == 0) {
            // ✅ ถ้าไม่มีรายการชำระเงิน แสดงข้อความ
            return Center(
              child: Text(
                'รอสตาฟเพิ่มรายการชำระเงิน',
                style: GoogleFonts.prompt(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return FutureBuilder<String>(
            future: _paymentController.getPromptPayId(),
            builder: (context, promptPaySnapshot) {
              if (promptPaySnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (promptPaySnapshot.hasError) {
                return Center(
                  child: Text(
                      'เกิดข้อผิดพลาดในการโหลด PromptPay ID: ${promptPaySnapshot.error}'),
                );
              }

              final promptPayId = promptPaySnapshot.data ?? '';

              return SingleChildScrollView(
                child: Container(
                  color: const Color(0xFF3B83F6),
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: QRCodeGenerate(
                          promptPayId: promptPayId,
                          amount: finalAmount, // ✅ แปลงให้เป็น double
                          width: 300,
                          height: 300,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '"฿ ${finalAmount.toStringAsFixed(2)}"',
                        style: GoogleFonts.prompt(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 255, 0, 85),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'ชำระเงินเสร็จแล้ว กรุณาอัปโหลดสลิป',
                        style: GoogleFonts.prompt(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _isUploading
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : ElevatedButton(
                              onPressed: _handleUploadSlip,
                              child: Text(
                                'อัปโหลดสลิป',
                                style: GoogleFonts.prompt(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                      const SizedBox(height: 20),
                      Container(
                        width: double
                            .infinity, // ทำให้ Container ขยายเต็มความกว้างของหน้าจอ
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'กรุณาทำตามขั้นตอนที่แนะนำ',
                              style: GoogleFonts.prompt(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '1. แคปหน้าจอ QR Code\n'
                              '2. เปิดแอปพลิเคชันธนาคารบนอุปกรณ์ของท่าน\n'
                              '3. เลือกไปที่ปุ่ม "สแกน" หรือ "QR Code" และกดที่ "รูปภาพ"\n'
                              '4. เลือกรูปภาพที่ท่านแคปไว้ และทำการชำระเงิน\n'
                              '5. หลังจากทำการชำระเงินเสร็จ กรุณาอัปโหลดสลิปการชำระเงิน\n'
                              '6. สามารถกลับไปตรวจสอบสถานะการชำระเงินในแอป MediBridge\n'
                              'หากจะยังไม่มีการอัปเดต กรุณาติดต่อฝ่ายลูกค้าสัมพันธ์ที่ 01-234-5678',
                              style: GoogleFonts.prompt(fontSize: 14),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
