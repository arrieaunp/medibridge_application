import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBBD4FB), 
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: Image.asset(
                'assets/images/bg_LandingPage.png',
                width: MediaQuery.of(context).size.width * 0.85,
                fit: BoxFit.contain,
              ),
            ),
          ),

          Positioned(
            bottom: 0, 
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              width: double.infinity, // ชิดขอบซ้าย-ขวา
              height: MediaQuery.of(context).size.height * 0.45, 
              decoration: const BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(60), 
                  topRight: Radius.circular(60), 
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, 
                children: [
                  Text(
                    'MediBridge',
                    style: GoogleFonts.prompt(
                      fontWeight: FontWeight.w700,
                      fontSize: 28, 
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  Text(
                    'จัดการการนัดหมายแพทย์ได้ง่าย ๆ \nเพียงปลายนิ้ว',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.prompt(
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Colors.black54, 
                    ),
                  ),
                  const SizedBox(height: 75),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 95, vertical: 15),
                      backgroundColor: const Color.fromARGB(255, 59, 131, 246), 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'เริ่มการใช้งาน',
                      style: GoogleFonts.prompt(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white, // สีตัวอักษรเป็นสีขาว
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
