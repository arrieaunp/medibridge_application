import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medibridge_application/widgets/top_rated_doctors.dart';
import './../../widgets/main_layout.dart';
import './../../controllers/patient_home_controller.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});
  @override
  _PatientHomePageState createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  final PatientHomeController _controller = PatientHomeController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? patientId;

  @override
  void initState() {
    super.initState();
    patientId = _auth.currentUser?.uid;
  }

  // Widget สำหรับ Skeleton Placeholder
  Widget skeleton({double? width, double? height, EdgeInsets? margin}) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B83F6),
        elevation: 0,
      ),
      body: MainLayout(
        selectedIndex: 0,
        child: ListView(
          children: [
            Stack(
              children: [
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/home_patient.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  left: 20,
                  child: FutureBuilder(
                    future: _controller.getUserData(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // แสดง Skeleton สำหรับส่วน header
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            skeleton(width: 200, height: 24),
                            const SizedBox(height: 10),
                            skeleton(width: 150, height: 16),
                          ],
                        );
                      } else if (snapshot.hasError) {
                        return const Text(
                          'เกิดข้อผิดพลาด',
                          style: TextStyle(color: Colors.white),
                        );
                      } else if (snapshot.hasData) {
                        final user = snapshot.data;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ยินดีต้อนรับ,\n${user?.firstName} ${user?.lastName}',
                              style: GoogleFonts.prompt(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '“Good health is \n the foundation of \n happiness”',
                              style: GoogleFonts.prompt(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ส่วนของเมนูบริการ
                  Text(
                    'What do you need?',
                    style: GoogleFonts.prompt(
                      color: const Color(0xFF3B83F6),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      _buildServiceCard(Icons.local_hospital, 'นัดแพทย์'),
                      _buildServiceCard(Icons.history, 'ประวัติการรักษา'),
                      _buildServiceCard(Icons.calendar_month, 'สถานะ'),
                      _buildServiceCard(Icons.payment, 'ชำระเงิน'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ส่วนของการแสดงการนัดหมายที่ใกล้จะถึง
                  Text(
                    'นัดหมายที่ใกล้จะถึง',
                    style: GoogleFonts.prompt(
                      color: const Color(0xFF3B83F6),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder(
                    future: _controller.getUpcomingAppointment(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // แสดง Skeleton สำหรับ Card นัดหมาย
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          color: const Color(0xFFE4EEFF),
                          elevation: 15,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 20.0, horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                skeleton(width: 100, height: 24),
                                const SizedBox(height: 8),
                                skeleton(width: 150, height: 16),
                              ],
                            ),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "เกิดข้อผิดพลาดในการโหลดข้อมูล",
                            style: GoogleFonts.prompt(
                              color: const Color(0xFF3B83F6),
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        );
                      } else if (snapshot.hasData) {
                        final appointment = snapshot.data;
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          color: const Color(0xFFE4EEFF),
                          elevation: 15,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 20.0, horizontal: 16.0),
                            child: appointment != null
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            appointment['date']!,
                                            style: GoogleFonts.prompt(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                          ),
                                          Text(
                                            appointment['time']!,
                                            style: GoogleFonts.prompt(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  const Color(0xFF3B83F6),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        appointment['doctor']!,
                                        style: GoogleFonts.prompt(
                                          fontSize: 16,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Text(
                                      "ไม่มีการนัดหมายล่าสุด",
                                      style: GoogleFonts.prompt(
                                        color: const Color(0xFF3B83F6),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder(
                    future: _controller.getTopRatedDoctors(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return skeleton(height: 150, margin: const EdgeInsets.symmetric(vertical: 10));
                      } else if (snapshot.hasError || !snapshot.hasData || (snapshot.data as List).isEmpty) {
                        return const SizedBox();
                      } else {
                        return TopRatedDoctorsCarousel(
                          doctors: snapshot.data as List<Map<String, dynamic>>,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(IconData icon, String label) {
    return Card(
      color: const Color(0xFFE4EEFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 5,
      child: InkWell(
        onTap: () {
          if (label == 'นัดแพทย์') {
            Navigator.pushNamed(context, '/appointment');
          } else if (label == 'สถานะ') {
            if (patientId != null) {
              Navigator.pushNamed(
                context,
                '/statusAppointment',
                arguments: {'patientId': patientId},
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("ไม่สามารถดึงข้อมูลผู้ป่วยได้")),
              );
            }
          } else if (label == 'ประวัติการรักษา') {
            if (patientId != null) {
              Navigator.pushNamed(
                context,
                '/medicalRecord',
                arguments: {'patientId': patientId},
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("ไม่สามารถดึงข้อมูลผู้ป่วยได้")),
              );
            }
          } else if (label == 'ชำระเงิน') {
            if (patientId != null) {
              Navigator.pushNamed(
                context,
                '/paymentStatus',
                arguments: {'patientId': patientId},
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("ไม่สามารถดึงข้อมูลผู้ป่วยได้")),
              );
            }
          } else {
            print('Selected $label');
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 25),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.prompt(),
            ),
          ],
        ),
      ),
    );
  }
}
