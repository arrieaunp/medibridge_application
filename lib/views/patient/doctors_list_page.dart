import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medibridge_application/controllers/doctors_list_controller.dart';
import 'package:medibridge_application/widgets/doctor_card.dart';

class DoctorsListPage extends StatefulWidget {
  const DoctorsListPage({Key? key}) : super(key: key);

  @override
  _DoctorsListPageState createState() => _DoctorsListPageState();
}

class _DoctorsListPageState extends State<DoctorsListPage> {
  final DoctorsListController controller = DoctorsListController();
  List<Map<String, dynamic>> allDoctors = [];
  List<Map<String, dynamic>> filteredDoctors = [];
  String searchQuery = "";
  String selectedSpecialization = "ทั้งหมด";

  final List<String> specializations = [
    "ทั้งหมด",
    "เวชศาสตร์ฉุกเฉิน",
    "จักษุแพทย์",
    "ศัลยกรรมทั่วไป",
    "กุมารเวชศาสตร์",
    "โสต ศอ นาสิก",
    "ศัลยกรรมกระดูกและข้อ",
    "โรคหัวใจ",
    "สูตินรีเวช",
    "อายุรศาสตร์",
    "จิตเวชศาสตร์",
  ];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    final doctors = await controller.fetchDoctors();
    setState(() {
      allDoctors = doctors;
      filteredDoctors = List.from(allDoctors); 
    });
  }

  void _filterDoctors() {
    setState(() {
      // ✅ ถ้ายังไม่มีการค้นหาหรือฟิลเตอร์ ให้แสดงแพทย์ทั้งหมด
      if (searchQuery.isEmpty && selectedSpecialization == "ทั้งหมด") {
        filteredDoctors = List.from(allDoctors);
        return;
      }

      // 🔎 ค้นหาตามชื่อและฟิลเตอร์ตามสาขา
      filteredDoctors = allDoctors.where((doctor) {
        final nameMatch =
            doctor['name'].toLowerCase().contains(searchQuery.toLowerCase());
        final specializationMatch = selectedSpecialization == "ทั้งหมด" ||
            doctor['specialization'] == selectedSpecialization;
        return nameMatch && specializationMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Doctors', style: GoogleFonts.prompt(fontWeight: FontWeight.bold,color: Colors.white)),
        backgroundColor: const Color(0xFF3B83F6),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔍 ค้นหาชื่อแพทย์
            TextField(
              decoration: InputDecoration(
                hintText: "ค้นหาแพทย์...",
                hintStyle: GoogleFonts.prompt(color: Colors.grey),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (query) {
                setState(() {
                  searchQuery = query;
                  _filterDoctors();
                });
              },
            ),
            const SizedBox(height: 10),

            // 📌 ฟิลเตอร์เลือก specialization
            DropdownButtonFormField<String>(
              value: selectedSpecialization,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: specializations.map((String spec) {
                return DropdownMenuItem<String>(
                  value: spec,
                  child: Text(spec, style: GoogleFonts.prompt(fontSize: 14)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSpecialization = value!;
                  _filterDoctors();
                });
              },
            ),

            const SizedBox(height: 10),

            // 🔹 รายชื่อแพทย์ (Responsive Grid)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          crossAxisCount, // แสดง 2 หรือ 3 การ์ดต่อแถว
                      childAspectRatio: 0.9, // ปรับขนาดการ์ดให้พอดี
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: filteredDoctors.length,
                    itemBuilder: (context, index) {
                      return DoctorCard(doctor: filteredDoctors[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
