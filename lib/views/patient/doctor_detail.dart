import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medibridge_application/controllers/doctor_detail_controller.dart';

class DoctorDetailPage extends StatefulWidget {
  final String doctorId;

  const DoctorDetailPage({Key? key, required this.doctorId}) : super(key: key);

  @override
  _DoctorDetailPageState createState() => _DoctorDetailPageState();
}

class _DoctorDetailPageState extends State<DoctorDetailPage> {
  final DoctorDetailController _controller = DoctorDetailController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<Map<String, dynamic>>(
        future: _controller.fetchDoctorData(widget.doctorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('ไม่พบข้อมูลแพทย์',
                    style: TextStyle(color: Colors.red)));
          }

          var doctor = snapshot.data!;
          var feedbacks = doctor['feedbacks'] as Map<String, dynamic>?;

          return SingleChildScrollView(
            child: Column(
              children: [
                // 🎨 Header + ปุ่มย้อนกลับ
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 200,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B83F6),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      left: 16,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 28),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Positioned(
                      top: 120,
                      left: MediaQuery.of(context).size.width / 2 - 50,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: doctor['profile_pic'] != null &&
                                doctor['profile_pic'].isNotEmpty
                            ? Image.network(
                                doctor['profile_pic'],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: const Icon(Icons.person, size: 50),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),

                // 🎯 ชื่อแพทย์ + สาขา
                Text(
                  '${doctor['first_name']} ${doctor['last_name']}',
                  style: GoogleFonts.prompt(
                      fontWeight: FontWeight.bold, fontSize: 22),
                ),
                Text(
                  doctor['specialization'] ?? 'ไม่มีข้อมูล',
                  style: GoogleFonts.prompt(fontSize: 16, color: Colors.blue),
                ),

                const SizedBox(height: 16),

                // 📚 การศึกษา
                _sectionTitle('การศึกษา'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    doctor['education'] ?? 'ไม่มีข้อมูล',
                    style:
                        GoogleFonts.prompt(fontSize: 14, color: Colors.black87),
                  ),
                ),

                const SizedBox(height: 12),

                // ⏰ เวลาทำงาน
                _sectionTitle('เวลาทำการ'),
                _infoCard(
                  title:
                      '${doctor['available_hours']['start']} - ${doctor['available_hours']['end']}',
                  icon: Icons.schedule,
                  color: Colors.orange,
                ),

                // 📅 วันที่ทำงาน
                _sectionTitle('วันทำงาน'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Wrap(
                    spacing: 8,
                    children: (doctor['available_days'] as List<dynamic>?)
                            ?.map((day) => _skillChip(day.toString()))
                            .toList() ??
                        [],
                  ),
                ),

                const SizedBox(height: 12),

                // 📧 ข้อมูลติดต่อ
                _sectionTitle('ติดต่อแพทย์'),
                _infoCard(
                  title: doctor['email'] ?? 'ไม่มีข้อมูล',
                  icon: Icons.email,
                  color: Colors.blue,
                ),
                _infoCard(
                  title: doctor['phone_number'] ?? 'ไม่มีข้อมูล',
                  icon: Icons.phone,
                  color: Colors.green,
                ),

                const SizedBox(height: 16),

                // 🗣️ ความคิดเห็นจากผู้ป่วย
                _sectionTitle('ความคิดเห็นจากผู้ป่วย'),
                feedbacks != null && feedbacks.isNotEmpty
                    ? Column(
                        children: feedbacks.values.map((feedback) {
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading:
                                  const Icon(Icons.comment, color: Colors.blue),
                              title: Text(feedback['comment'],
                                  style: GoogleFonts.prompt()),

                              // ⭐ คะแนนรีวิว
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < feedback['rating']
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.orange,
                                        size: 16,
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'ยังไม่มีความคิดเห็น',
                          style: GoogleFonts.prompt(color: Colors.grey),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 📌 UI Helper Functions
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6, top: 16),
      child: Text(title,
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
  // 📌 Widgets

  Widget _infoCard(
      {required String title, required IconData icon, required Color color}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: GoogleFonts.prompt(fontSize: 14)),
      ),
    );
  }

  Widget _skillChip(String skill) {
    return Chip(
      label: Text(skill, style: GoogleFonts.prompt(fontSize: 12)),
      backgroundColor: Colors.blue.withOpacity(0.1),
    );
  }
}
