import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medibridge_application/controllers/doctor_home_controller.dart';
import 'package:medibridge_application/widgets/doc_main_layout.dart';

class DoctorHomePage extends StatefulWidget {
  final String doctorId;

  const DoctorHomePage({
    Key? key,
    required this.doctorId,
  }) : super(key: key);

  @override
  _DoctorHomePageState createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  final DoctorHomeController controller = DoctorHomeController();
  late Future<String> fetchDoctorNameFuture;
  late Future<Map<String, dynamic>?> fetchUpcomingAppointmentFuture;

  @override
  void initState() {
    super.initState();
    print(
        "🟢 [DEBUG] doctorId ที่รับมาใน DoctorHomePage: '${widget.doctorId}'");

    // Initialize Futures safely
    fetchDoctorNameFuture = controller.fetchDoctorName(widget.doctorId);
    fetchUpcomingAppointmentFuture =
        controller.fetchUpcomingAppointment(widget.doctorId);
  }

  String formatDateFromTimestamp(Map<String, dynamic> appointment) {
    var rawDate = appointment['appointment_date'];
    print('Raw appointment_date: $rawDate');
    print('Type: ${rawDate?.runtimeType}');

    if (rawDate is DateTime) {
      // ✅ Handle DateTime directly
      return DateFormat('d MMMM', 'th_TH').format(rawDate);
    } else if (rawDate is Timestamp) {
      return DateFormat('d MMMM', 'th_TH').format(rawDate.toDate());
    } else if (rawDate is String) {
      try {
        DateTime date = DateTime.parse(rawDate);
        return DateFormat('d MMMM', 'th_TH').format(date);
      } catch (e) {
        print('Error parsing string date: $e');
      }
    }
    return 'ไม่พบวันที่';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(5),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF3B83F6),
          elevation: 0,
        ),
      ),
      body: DocMainLayout(
        selectedIndex: 0,
        doctorId: widget.doctorId,
        child: FutureBuilder<String>(
          future: fetchDoctorNameFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return const Center(child: Text('Error loading doctor name'));
            }

            final doctorName = snapshot.data ?? 'ไม่ทราบชื่อ';
            return _buildHomeContent(context, doctorName);
          },
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, String doctorName) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          Stack(
            children: [
              Container(
                height: 220,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/home_doctor.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ยินดีต้อนรับ,',
                      style: GoogleFonts.prompt(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'แพทย์ $doctorName ',
                      style: GoogleFonts.prompt(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 35),
                    Text(
                      '“Good health is \n the foundation of \n happiness”',
                      style: GoogleFonts.prompt(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          //Card nearest Appointments
          FutureBuilder<Map<String, dynamic>?>(
            future: fetchUpcomingAppointmentFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || snapshot.data == null) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'ไม่มีนัดหมายที่ใกล้ถึง',
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final appointment = snapshot.data!;
              return LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'นัดหมายที่ใกล้จะถึง',
                              style: GoogleFonts.prompt(
                                  fontSize: 14,
                                  color: const Color(0xFF3B83F6),
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    formatDateFromTimestamp(appointment),
                                    style: GoogleFonts.prompt(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    '${appointment['appointment_time']}',
                                    style: GoogleFonts.prompt(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF3B83F6),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${appointment['patient_name']}',
                              style: GoogleFonts.prompt(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                width: constraints.maxWidth * 0.4,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 5,
                                    backgroundColor: const Color(0xFF3B83F6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  onPressed: () {
                                    final patientId =
                                        appointment['patient_id']?.toString() ??
                                            '';
                                    if (patientId.isNotEmpty) {
                                      Navigator.pushNamed(
                                        context,
                                        '/patienthistory',
                                        arguments: {
                                          'patientId': patientId,
                                          'doctorId': widget
                                              .doctorId, // ✅ ส่ง doctorId ที่ถูกต้อง
                                        },
                                      );
                                    } else {
                                      print('patient_id is null or empty');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('ไม่พบข้อมูลผู้ป่วย')),
                                      );
                                    }
                                  },
                                  child: Text(
                                    'ตรวจสอบประวัติ',
                                    style: GoogleFonts.prompt(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 20),

          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'เมนูหลัก',
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
            child: Row(
              children: [
                _buildMenuItem(
                  context,
                  "ตารางเวร",
                  Icons.medical_services,
                  '/doctorSchedule',
                  {'doctorId': widget.doctorId},
                ),
                const SizedBox(width: 16),
                _buildMenuItem(
                  context,
                  "ประวัติการรักษา",
                  Icons.assignment,
                  '/medicalRecordList',
                  {'doctorId': widget.doctorId},
                ),
                const SizedBox(width: 16),
                _buildMenuItem(
                  context,
                  "Dashboard",
                  Icons.dashboard,
                  '/doctorDashboard',
                  {'doctor_id': widget.doctorId},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget สร้างปุ่มเมนู
Widget _buildMenuItem(
    BuildContext context, String title, IconData icon, String route,
    [Map<String, dynamic>? arguments]) {
  return GestureDetector(
    onTap: () {
      print(
          "🟢 [DEBUG] กำลังกดเข้า Dashboard ด้วย doctor_id: '${arguments?['doctor_id']}'");

      Navigator.pushNamed(
        context,
        route,
        arguments: arguments, // ส่ง arguments ไปยัง route
      );
    },
    child: Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFE4EEFF),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.grey,
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 40, color: Colors.black),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.prompt(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    ),
  );
}
