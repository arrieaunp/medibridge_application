import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medibridge_application/widgets/main_layout.dart';

class PatientNotificationPage extends StatefulWidget {
  final String patientId;
  const PatientNotificationPage({Key? key, required this.patientId})
      : super(key: key);

  @override
  _PatientNotificationPageState createState() =>
      _PatientNotificationPageState();
}

class _PatientNotificationPageState extends State<PatientNotificationPage> {
  @override
  void initState() {
    super.initState();
    var currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      debugPrint("✅ [DEBUG] ผู้ป่วยเข้าสู่ระบบ: ${currentUser.uid}");
    } else {
      debugPrint("🚫 [DEBUG] ผู้ป่วยยังไม่ได้เข้าสู่ระบบ");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("กรุณาเข้าสู่ระบบ"));
    }

    debugPrint("✅ [DEBUG] User Authenticated: ${user.uid}");

    return MainLayout(
        selectedIndex: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              "แจ้งเตือนผู้ป่วย",
              style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Notifications')
                .where('recipient_id', isEqualTo: user.uid)
                .where('role', isEqualTo: 'Patient')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "ไม่มีการแจ้งเตือน",
                    style: GoogleFonts.prompt(
                        fontSize: 16, color: Colors.blueGrey),
                  ),
                );
              }

              final notifications = snapshot.data!.docs;

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final doc = notifications[index];
                  final notification = doc.data() as Map<String, dynamic>;
                  debugPrint("🟡 [DEBUG] doc.id จาก Firestore: ${doc.id}");

                  String formattedTime = notification['timestamp'] != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(
                          (notification['timestamp'] as Timestamp).toDate())
                      : "ไม่ระบุเวลา";

                  return Dismissible(
                    key: ValueKey(doc.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete,
                          color: Colors.white, size: 32),
                    ),
                    confirmDismiss: (direction) async {
                      debugPrint("🔍 [DEBUG] confirmDismiss ถูกเรียก");
                      bool? shouldDelete = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('ยืนยันการลบ'),
                            content: const Text(
                                'คุณต้องการลบการแจ้งเตือนนี้ใช่หรือไม่?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  print("❌ [DEBUG] ยกเลิกการลบ");
                                  Navigator.of(context).pop(false);
                                },
                                child: const Text('ยกเลิก'),
                              ),
                              TextButton(
                                onPressed: () {
                                  print("✅ [DEBUG] ยืนยันการลบ");
                                  Navigator.of(context).pop(true);
                                },
                                child: const Text('ลบ'),
                              ),
                            ],
                          );
                        },
                      );
                      debugPrint(
                          "🟡 [DEBUG] ผลการยืนยันจาก confirmDismiss: $shouldDelete");
                      return shouldDelete ?? false;
                    },
                    onDismissed: (direction) async {
                      String docId = doc.id;
                      debugPrint(
                          "🚀 [DEBUG] ถึง onDismissed แล้วสำหรับ Document: $docId");

                      try {
                        // 🟡 1) ตรวจสอบสิทธิ์การอ่าน (เช็คว่าอ่านได้ก่อนจะลบได้)
                        var testRead = await FirebaseFirestore.instance
                            .collection('Notifications')
                            .doc(docId)
                            .get();

                        debugPrint(
                            "🟡 [DEBUG] Read Check: ${testRead.exists ? 'อ่านได้' : 'อ่านไม่ได้'}");

                        // 🟠 2) ตรวจสอบการลบ
                        await FirebaseFirestore.instance
                            .collection('Notifications')
                            .doc(docId)
                            .delete()
                            .then((_) {
                          debugPrint("✅ [DEBUG] ลบการแจ้งเตือนสำเร็จ: $docId");
                        }).catchError((error) {
                          debugPrint(
                              "❌ [DEBUG] Firebase Error: ${error.code} - ${error.message}");
                        });
                      } catch (e) {
                        debugPrint("❌ [DEBUG] ลบไม่สำเร็จ (Catch Block): $e");
                      }
                    },
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(
                          notification['title'] ?? 'ไม่มีหัวข้อ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          notification['body'] ?? 'ไม่มีรายละเอียด',
                        ),
                        trailing: Text(
                          formattedTime,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
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

void testDeleteNotification(String docId) async {
  try {
    print("🟡 [DEBUG] กำลังทดสอบการลบ Document: $docId");
    await FirebaseFirestore.instance
        .collection('Notifications')
        .doc(docId)
        .delete()
        .then((_) {
      print("✅ [DEBUG] ทดสอบลบสำเร็จ: $docId");
    }).catchError((error) {
      print("❌ [DEBUG] Firebase Error: ${error.code} - ${error.message}");
    });
  } catch (e) {
    print("❌ [DEBUG] ลบไม่สำเร็จ (Catch Block): $e");
  }
}
