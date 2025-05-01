import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MedicalRecordCard extends StatelessWidget {
  final String doctorName;
  final String doctorProfilePic;
  final String treatmentDate;
  final String diagnosis;
  final VoidCallback onTap;
  final VoidCallback onFeedbackPressed;

  const MedicalRecordCard({
    Key? key,
    required this.doctorName,
    required this.doctorProfilePic,
    required this.treatmentDate,
    required this.diagnosis,
    required this.onTap,
    required this.onFeedbackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ แถวแรก: วันที่ และ ปุ่ม ">"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "นัดหมายล่าสุด: $treatmentDate",
                    style: GoogleFonts.prompt(
                        fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey), // ปุ่ม ">"
                ],
              ),
              const SizedBox(height: 8),

              // ✅ แถวสอง: รูปแพทย์ + ข้อมูล
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🔹 รูปแพทย์
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: doctorProfilePic.isNotEmpty
                        ? NetworkImage(doctorProfilePic)
                        : null,
                    backgroundColor: doctorProfilePic.isEmpty ? Colors.grey[300] : null,
                    child: doctorProfilePic.isEmpty
                        ? const Icon(Icons.person, size: 30, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),

                  // 🔹 ชื่อแพทย์ + การวินิจฉัย (เรียงใน Column)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctorName,
                          style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "การวินิจฉัย: $diagnosis",
                          style: GoogleFonts.prompt(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ✅ ปุ่ม Feedback (ชิดขวา)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onFeedbackPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text("Feedback", style: GoogleFonts.prompt(color: Colors.white,fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
