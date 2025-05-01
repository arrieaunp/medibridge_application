import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medibridge_application/widgets/staff_main_layout.dart';

class StaffHomePage extends StatelessWidget {
  final Color appBarColor;

  const StaffHomePage({Key? key, this.appBarColor = const Color(0xFF3B83F6)})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: appBarColor,
        elevation: 0,
      ),
      body: StaffMainLayout(
        selectedIndex: 0,
        child: _buildHomeContent(context),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          Stack(
            children: [
              Container(
                height: 200,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/home_staff.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 20,
                child: Text(
                  'ยินดีต้อนรับ, \nเจ้าหน้าที่',
                  style: GoogleFonts.prompt(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'What do you need?',
              style: GoogleFonts.prompt(
                fontSize: 20,
                color: const Color(0xFF3B83F6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Menu Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildMenuItem(
                  context,
                  "การนัดหมาย",
                  Icons.local_hospital,
                  '/appointmentManagement',
                ),
                _buildMenuItem(
                  context,
                  "ตารางเวรแพทย์",
                  Icons.calendar_month,
                  '/doctorSchedules',
                ),
                _buildMenuItem(
                  context,
                  "จัดการผู้ใช้งาน",
                  Icons.person_add_alt_1,
                  '/manageUser',
                ),
                _buildMenuItem(
                  context,
                  "รายการชำระเงิน",
                  Icons.attach_money,
                  '/paymentRecords',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget สร้างปุ่มเมนู
  Widget _buildMenuItem(
      BuildContext context, String title, IconData icon, String route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE4EEFF),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          const BoxShadow(
            color: Colors.grey,
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF3B83F6), size: 28),
        title: Text(
          title,
          style: GoogleFonts.prompt(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}
