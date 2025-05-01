import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medibridge_application/widgets/main_layout.dart';
import '../../controllers/payment_controller.dart';

class PaymentStatusPage extends StatefulWidget {
  final String patientId; // รับ patientId เพื่อแสดงข้อมูลชำระเงินของผู้ป่วย

  const PaymentStatusPage({Key? key, required this.patientId})
      : super(key: key);

  @override
  _PaymentStatusPageState createState() => _PaymentStatusPageState();
}

class _PaymentStatusPageState extends State<PaymentStatusPage>
    with SingleTickerProviderStateMixin {
  final PaymentController _paymentController = PaymentController();
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
        selectedIndex: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'รายการชำระเงิน',
              style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Text(
                    'รอชำระเงิน',
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
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPaymentList('รอชำระเงิน'),
              _buildPaymentList('ยืนยันแล้ว'),
              _buildPaymentList('ยกเลิก'),
            ],
          ),
        ));
  }

  Widget _buildPaymentList(String statusFilter) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _paymentController.getPaymentsForPatient(
          widget.patientId, statusFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'ไม่มีรายการชำระเงิน',
              style: GoogleFonts.prompt(
                  fontSize: 16,
                  color: Colors.grey),
            ),
          );
        } else {
          final payments = snapshot.data!;

          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                    title: Text(
                      DateFormat('dd MMMM yyyy').format(
                        (payment['appointment_date'] as Timestamp).toDate(),
                      ),
                      style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${payment['appointment_time']} น.\nแพทย์: ${payment['doctor_name']}',
                      style: GoogleFonts.prompt(),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          payment['status'] == 'รอชำระเงิน'
                              ? Icons.credit_card
                              : Icons.check_circle,
                          color: payment['status'] == 'รอชำระเงิน'
                              ? Colors.orange
                              : Colors.green,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          payment['status'] ?? 'ไม่ทราบสถานะ',
                          style: GoogleFonts.prompt(fontSize: 12),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (payment['status'] == 'รอชำระเงิน') {
                        Navigator.pushNamed(
                          context,
                          '/paymentPage', // ใส่ชื่อ route ของหน้าชำระเงินให้ถูกต้อง
                          arguments: {
                            'appointmentId': payment['appointment_id'],
                            'amount': payment['amount'],
                            'doctorName': payment['doctor_name'],
                            'appointmentDate': payment['appointment_date'],
                            'appointmentTime': payment['appointment_time'],
                            'promptPayId':
                                'promptpayID_ที่ต้องการ', // ต้องกำหนด promptPayId ที่ใช้
                          },
                        );
                        print('กดไปหน้าชำระเงิน');
                      }
                    }),
              );
            },
          );
        }
      },
    );
  }
}
