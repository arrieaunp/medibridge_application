import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medibridge_application/views/shared/login_page.dart';

// ฟังก์ชัน sign out ผู้ใช้งาน
void signOutUser(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => LoginPage()),
    (route) => false,
  );
}

//dialog ยืนยันการ logout
void showLogoutConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('ออกจากระบบ',style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        content: Text('คุณต้องการออกจากระบบใช่หรือไม่?',style: GoogleFonts.prompt()),
        actions: [
          TextButton(
            child: Text('ยกเลิก',style: GoogleFonts.prompt(fontWeight: FontWeight.bold,color: Colors.red)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child:  Text('ยืนยัน',style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.of(context).pop();
              signOutUser(context);
            },
          ),
        ],
      );
    },
  );
}
