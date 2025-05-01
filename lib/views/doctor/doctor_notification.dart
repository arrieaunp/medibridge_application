import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medibridge_application/widgets/doc_main_layout.dart';

class DoctorNotificationPage extends StatelessWidget {
  final String doctorId;
  const DoctorNotificationPage({
    Key? key,
    required this.doctorId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "แจ้งเตือน",
            style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: DocMainLayout(
          selectedIndex: 2,
          doctorId: doctorId,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Notifications')
                .where('role', isEqualTo: 'Doctor')
                .where('recipient_id', isEqualTo: doctorId)
                .orderBy('timestamp', descending: true) // ✅ เรียงตามเวลา
                .snapshots(),
            builder: (context, snapshot) {
              print('📢 แจ้งเตือนที่โหลด: ${snapshot.data?.docs.length}');

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                    child: Text("ไม่มีการแจ้งเตือน",
                        style: GoogleFonts.prompt(color: Colors.grey)));
              }

              final notifications = snapshot.data!.docs;

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final doc = notifications[index];
                  final notification = doc.data() as Map<String, dynamic>;

                  String formattedTime = notification['timestamp'] != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(
                          (notification['timestamp'] as Timestamp).toDate())
                      : "ไม่ระบุเวลา";

                  return Dismissible(
                    key: Key(doc.id), // ✅ ใช้ Document ID เป็น Key
                    direction:
                        DismissDirection.endToStart, // ✅ ปัดจากขวาไปซ้ายเพื่อลบ
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete,
                          color: Colors.white, size: 32),
                    ),
                    confirmDismiss: (direction) async {
                      bool? shouldDelete = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                              'ยืนยันการลบ',
                              style: GoogleFonts.prompt(
                                  fontWeight: FontWeight.bold),
                            ),
                            content: Text(
                              'คุณต้องการลบการแจ้งเตือนนี้ใช่หรือไม่?',
                              style: GoogleFonts.prompt(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child:
                                    Text('ยกเลิก', style: GoogleFonts.prompt()),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text('ลบ',
                                    style: GoogleFonts.prompt(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          );
                        },
                      );

                      print(
                          '🗑 การลบได้รับการยืนยัน: $shouldDelete'); // ✅ เช็คว่าผู้ใช้กดลบจริงไหม

                      return shouldDelete;
                    },

                    onDismissed: (direction) async {
                      try {
                        print('🗑 กำลังลบแจ้งเตือน: ${doc.id}');

                        await FirebaseFirestore.instance
                            .collection('Notifications')
                            .doc(doc.id)
                            .delete()
                            .then((_) {
                          print('✅ ลบสำเร็จใน Firestore');
                        }).catchError((error) {
                          print('❌ เกิดข้อผิดพลาดขณะลบ: $error');
                        });

                        // 🔍 ตรวจสอบว่าถูกลบจริงหรือไม่
                        final docCheck = await FirebaseFirestore.instance
                            .collection('Notifications')
                            .doc(doc.id)
                            .get();

                        if (docCheck.exists) {
                          print('❌ เอกสารยังอยู่ใน Firestore! ลบไม่สำเร็จ');
                        } else {
                          print('✅ เอกสารถูกลบจาก Firestore แล้ว!');
                        }

                        // ✅ อัปเดต UI หลังจากลบ
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ลบการแจ้งเตือนสำเร็จ'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        print('❌ เกิดข้อผิดพลาดในการลบ: $e');
                      }
                    },
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(
                          notification['title'] ?? 'ไม่มีหัวข้อ',
                          style: GoogleFonts.prompt(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3B83F6)),
                        ),
                        subtitle: Text(
                          notification['body'] ?? 'ไม่มีรายละเอียด',
                          style: GoogleFonts.prompt(),
                        ),
                        trailing: Text(
                          formattedTime,
                          style: GoogleFonts.prompt(
                              fontSize: 12, color: Colors.grey),
                        ),
                        onTap: () {
                          print('แตะโนติ');
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ));
  }
}
