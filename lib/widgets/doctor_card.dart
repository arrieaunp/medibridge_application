import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const DoctorCard({Key? key, required this.doctor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/doctorDetail',
          arguments: {'doctor_id': doctor['id']},
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
        shadowColor: Colors.black26,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🏥 รูปโปรไฟล์ของแพทย์
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.network(
                  doctor['profile_pic'],
                  height: 75,
                  width: 75,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset('assets/images/doctor_placeholder.png',
                        height: 75, width: 75, fit: BoxFit.cover);
                  },
                ),
              ),
              const SizedBox(height: 10),

              // 👨‍⚕️ ชื่อแพทย์
              Text(
                doctor['name'],
                textAlign: TextAlign.center,
                style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),

              // 🏥 สาขาแพทย์
              Text(
                doctor['specialization'],
                textAlign: TextAlign.center,
                style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
