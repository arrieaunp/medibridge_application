import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medibridge_application/controllers/appointment_controller.dart';

class AppointmentPage2 extends StatefulWidget {
  final AppointmentController controller;
  const AppointmentPage2({Key? key, required this.controller}) : super(key: key);

  @override
  _AppointmentPage2State createState() => _AppointmentPage2State();
}

class _AppointmentPage2State extends State<AppointmentPage2> {
  List<Map<String, dynamic>> allDoctors = []; // เก็บรายชื่อแพทย์ทั้งหมด
  List<Map<String, dynamic>> filteredDoctors = [];
  String? selectedSpecialization;

  // ฟังก์ชันกรองรายชื่อแพทย์จาก allDoctors
  void _filterDoctors(String query) {
    setState(() {
      filteredDoctors = allDoctors.where((doctor) {
        final firstName = (doctor['first_name'] ?? '').toLowerCase();
        final lastName = (doctor['last_name'] ?? '').toLowerCase();
        final specialization = (doctor['specialization'] ?? '').toLowerCase();
        final lowerCaseQuery = query.toLowerCase();

        bool matchesSearch = firstName.contains(lowerCaseQuery) ||
            lastName.contains(lowerCaseQuery) ||
            specialization.contains(lowerCaseQuery);

        bool matchesSpecialization = selectedSpecialization == null ||
            selectedSpecialization!.isEmpty ||
            doctor['specialization'] == selectedSpecialization;

        return matchesSearch && matchesSpecialization;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppointmentController controller = widget.controller;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'นัดหมายแพทย์',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: controller.getAvailableDoctors(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // แสดง Skeleton ในขณะรอโหลดข้อมูล
              return ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                        ),
                      ),
                      title: Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.grey[300],
                      ),
                      subtitle: Container(
                        width: 150,
                        height: 14,
                        color: Colors.grey[300],
                      ),
                    ),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'เกิดข้อผิดพลาดในการโหลดรายชื่อแพทย์',
                  style: GoogleFonts.prompt(color: Colors.red),
                ),
              );
            } else if (snapshot.hasData) {
              // เก็บข้อมูลที่โหลดครั้งแรกไว้ในตัวแปร allDoctors
              if (allDoctors.isEmpty) {
                allDoctors = snapshot.data!;
                filteredDoctors = allDoctors;
              }
              
              // ดึงรายการสาขาไม่ซ้ำกัน
              List<String> specializations = allDoctors
                  .map<String>((doctor) => doctor['specialization'].toString())
                  .toSet()
                  .toList();
              specializations.sort();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เลือกแพทย์ที่ต้องการนัดหมาย',
                    style: GoogleFonts.prompt(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'ค้นหาแพทย์...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (value) {
                      _filterDoctors(value);
                    },
                  ),
                  const SizedBox(height: 10),
                  // Filter Chips
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ChoiceChip(
                          label: Text('ทุกสาขา', style: GoogleFonts.prompt()),
                          selected: selectedSpecialization == null,
                          onSelected: (isSelected) {
                            setState(() {
                              selectedSpecialization = null;
                              _filterDoctors("");
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Wrap(
                          spacing: 8,
                          children: specializations.map((specialization) {
                            return ChoiceChip(
                              label: Text(specialization,
                                  style: GoogleFonts.prompt()),
                              selected: selectedSpecialization == specialization,
                              onSelected: (isSelected) {
                                setState(() {
                                  selectedSpecialization =
                                      isSelected ? specialization : null;
                                  _filterDoctors("");
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // รายชื่อแพทย์
                  Expanded(
                    child: filteredDoctors.isEmpty
                        ? Center(
                            child: Text(
                              'ไม่มีแพทย์ว่างในเวลาที่เลือก',
                              style: GoogleFonts.prompt(
                                  fontWeight: FontWeight.w200,
                                  color: Colors.red),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredDoctors.length,
                            itemBuilder: (context, index) {
                              final doctor = filteredDoctors[index];
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/doctorDetail',
                                      arguments: {
                                        'doctor_id': doctor['doctor_id'],
                                      },
                                    );
                                  },
                                  child: ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: doctor['profile_pic'] != null &&
                                                doctor['profile_pic'].isNotEmpty
                                            ? Image.network(
                                                doctor['profile_pic'],
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.person,
                                                    size: 40,
                                                    color: Colors.white),
                                              ),
                                      ),
                                    ),
                                    title: Text(
                                      '${doctor['first_name']} ${doctor['last_name']}',
                                      style: GoogleFonts.prompt(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                        'สาขา: ${doctor['specialization']}'),
                                    trailing: ElevatedButton(
                                      onPressed: () async {
                                        final isAvailable =
                                            await controller.isTimeSlotAvailable(
                                          doctorId: doctor['doctor_id'],
                                          date: controller.selectedDate!,
                                          time: controller.selectedTime!,
                                        );
                                        if (isAvailable) {
                                          Navigator.pushNamed(
                                            context,
                                            '/appointmentReview',
                                            arguments: {
                                              'patient_id': FirebaseAuth.instance
                                                  .currentUser?.uid,
                                              'doctor_id': doctor['doctor_id'],
                                              'doctor_name':
                                                  '${doctor['first_name']} ${doctor['last_name']}',
                                              'specialization':
                                                  doctor['specialization'],
                                              'appointment_date':
                                                  controller.getSelectedDate(),
                                              'appointment_time':
                                                  controller.getSelectedTime(),
                                            },
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'เวลานี้ไม่ว่าง กรุณาเลือกเวลาอื่น'),
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF3B83F6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: Text(
                                        'นัดหมาย',
                                        style: GoogleFonts.prompt(
                                          fontSize: 15,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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
    );
  }
}
