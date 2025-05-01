import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:medibridge_application/controllers/appointment_controller.dart';
import 'package:medibridge_application/controllers/medical_record_controller.dart';
import 'package:medibridge_application/services/auth_service.dart';
import 'package:medibridge_application/services/notification_service.dart';
import 'package:medibridge_application/views/doctor/2_medical_record_list_page.dart';
import 'package:medibridge_application/views/doctor/3_medical_record_list_page.dart';
import 'package:medibridge_application/views/doctor/doctor_dashboard_page.dart';
import 'package:medibridge_application/views/doctor/doctor_notification.dart';
import 'package:medibridge_application/views/doctor/doctor_schedule_page.dart';
import 'package:medibridge_application/views/doctor/home_doctor.dart';
import 'package:medibridge_application/views/doctor/1_medical_record_list_page.dart';
import 'package:medibridge_application/views/doctor/patient_history_page.dart';
import 'package:medibridge_application/views/doctor/profile_doctor.dart';
import 'package:medibridge_application/views/patient/doctor_detail.dart';
import 'package:medibridge_application/views/patient/doctors_list_page.dart';
import 'package:medibridge_application/views/patient/feedback_page.dart';
import 'package:medibridge_application/views/patient/medical_record_detail_page.dart';
import 'package:medibridge_application/views/shared/forgot_password_page.dart';
import 'package:medibridge_application/views/staff/1_manage_doctor_schedule_page.dart';
import 'package:medibridge_application/views/staff/2_manage_payment_page.dart';
import 'package:medibridge_application/views/staff/home_staff.dart';
import 'package:medibridge_application/views/staff/manage_appointment_page.dart';
import 'package:medibridge_application/views/staff/1_manage_payment_page.dart';
import 'package:medibridge_application/views/staff/manage_user_page.dart';
import 'package:medibridge_application/views/staff/profile_staff.dart';
import 'package:medibridge_application/views/staff/staff_notification.dart';
import 'package:provider/provider.dart';
import 'views/shared/landing_page.dart';
import 'views/shared/login_page.dart';
import 'views/patient/views.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(); // Initialize Firebase
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  await initializeDateFormatting('th_TH', null);

  AuthService authService = AuthService();
  await authService.loadStaffCredentials();
  // ✅ ลองล็อกอินอัตโนมัติ ถ้ามี Staff Credentials
  await authService.reLogin();

  // ขอ FCM Token
  String? fcmToken = await messaging.getToken();
  if (fcmToken != null) {
    debugPrint("FCM Token: $fcmToken"); // แสดง FCM Token ใน Console
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppointmentController()),
        ChangeNotifierProvider(create: (context) => MedicalRecordController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // เรียก `NotificationService` พร้อมส่ง `context`
    NotificationService.instance.initialize(context);
    // ✅ เรียก `listenForFcmTokenChanges()` เมื่อแอปเริ่มต้น
    AuthService().listenForFcmTokenChanges();

    return MaterialApp(
      navigatorKey:
          navigatorKey, // ✅ ใช้ navigatorKey เพื่อนำทางใน Firebase Messaging

      title: 'MediBridge',
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Text('An error occurred. Please try again.'),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            final String userId = snapshot.data!.uid;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('User')
                  .doc(userId)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (userSnapshot.hasError || userSnapshot.data == null) {
                  return const Scaffold(
                    body: Center(
                      child:
                          Text('Failed to load user data. Please try again.'),
                    ),
                  );
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>?;
                if (userData != null) {
                  final String role = userData['role'] ?? 'undefined';

                  if (role == 'Doctor') {
                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('Doctors')
                          .where('user_id', isEqualTo: userId)
                          .get(),
                      builder: (context, doctorSnapshot) {
                        if (doctorSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (doctorSnapshot.hasError ||
                            doctorSnapshot.data == null ||
                            doctorSnapshot.data!.docs.isEmpty) {
                          return const Scaffold(
                            body: Center(
                              child: Text(
                                'Doctor data not found. Please log in again.',
                              ),
                            ),
                          );
                        }

                        final String doctorId =
                            doctorSnapshot.data!.docs.first.id; // ดึง doctorId
                        debugPrint(
                            "🟢 [DEBUG] โหลด doctor_id สำเร็จ: '$doctorId'");
                        if (doctorId.isEmpty) {
                          debugPrint(
                              "❌ [ERROR] doctor_id เป็นค่าว่าง! ตรวจสอบ Firestore");
                        }

                        return DoctorHomePage(doctorId: doctorId);
                      },
                    );
                  } else if (role == 'Patient') {
                    return const PatientHomePage();
                  } else if (role == 'Staff') {
                    return const StaffHomePage();
                  } else {
                    return const Scaffold(
                      body: Center(
                        child: Text('Unknown role. Please contact support.'),
                      ),
                    );
                  }
                } else {
                  return const Scaffold(
                    body: Center(
                      child: Text('User data is invalid. Please log in again.'),
                    ),
                  );
                }
              },
            );
          } else {
            return const LandingPage();
          }
        },
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/medicalRecord':
            return MaterialPageRoute(
              builder: (context) => MedicalHistoryPage(),
            );

          case '/doctorDetail':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) =>
                  DoctorDetailPage(doctorId: args['doctor_id']),
            );

          case '/doctorDashboard':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            final doctorId = args['doctor_id'] as String? ?? '';
            debugPrint(
                "🟢 [DEBUG] doctor_id ที่ถูกส่งไปยัง Dashboard: '$doctorId'");

            if (doctorId.isEmpty) {
              debugPrint(
                  "❌ [ERROR] doctor_id เป็นค่าว่าง! ตรวจสอบการส่งค่าใน Navigator.pushNamed()");
            }

            return MaterialPageRoute(
              builder: (context) => DoctorDashboardPage(doctorId: doctorId),
            );
          default:
            return null;
        }
      },

      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/patientHome': (context) => const PatientHomePage(),
        '/doctorHome': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          if (args == null || !args.containsKey('doctorId')) {
            return const Scaffold(
              body: Center(
                child: Text('Missing or invalid arguments.'),
              ),
            );
          }
          return DoctorHomePage(doctorId: args['doctorId']);
        },
        '/staffHome': (context) => const StaffHomePage(),
        '/patientProfile': (context) => const PatientProfilePage(),
        '/appointment': (context) => const AppointmentPage(),
        '/appointment2': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>;
          return AppointmentPage2(controller: args['controller']);
        },
        '/appointmentReview': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>;
          return AppointmentPage3(appointmentDetails: args);
        },
        '/statusAppointment': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>;
          if (args.containsKey('patientId')) {
            return StatusAppointmentPage(patientId: args['patientId']);
          } else {
            return const Scaffold(
              body: Center(
                  child: Text("Invalid or missing arguments for status page")),
            );
          }
        },
        '/medicalRecord': (context) => MedicalHistoryPage(),
        '/paymentStatus': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>;
          if (args.containsKey('patientId')) {
            return PaymentStatusPage(patientId: args['patientId']);
          } else {
            return const Scaffold(
              body: Center(
                  child: Text(
                      "Invalid or missing arguments for payment status page")),
            );
          }
        },
        '/paymentPage': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>;
          return PaymentPage(
            appointmentId: args['appointmentId'],
            amount: args['amount'],
            doctorName: args['doctorName'],
            appointmentDate: (args['appointmentDate'] as Timestamp)
                .toDate(), // แปลง Timestamp เป็น DateTime
            appointmentTime: args['appointmentTime'],
            promptPayId: args['promptPayId'],
          );
        },
        '/patientNotifications': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>;
          return PatientNotificationPage(patientId: args['patientId']);
        },
        '/manageUser': (context) => const ManageUserPage(),
        '/staffProfile': (context) => const StaffProfilePage(),
        '/appointmentManagement': (context) => const ManageAppointmentPage(),
        '/paymentRecords': (context) => const ManagePaymentPage(),
        '/paymentMethod': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>;
          if (args.containsKey('appointmentId')) {
            return ManagePaymentPage2(appointmentId: args['appointmentId']);
          } else {
            return const Scaffold(
              body: Center(
                child: Text(
                    'Invalid or missing arguments for payment method page'),
              ),
            );
          }
        },
        '/doctorSchedules': (context) => ManageDoctorSchedulePage(),
        '/doctorProfile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>;
          return DoctorProfilePage(doctorId: args['doctorId']);
        },
        '/doctorSchedule': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          if (args == null || !args.containsKey('doctorId')) {
            return const Scaffold(
              body: Center(
                child: Text(
                    'Missing or invalid arguments for doctor schedule page.'),
              ),
            );
          }
          return DoctorSchedulePage(doctorId: args['doctorId']);
        },
        // '/doctorSchedule': (context) {
        //   final args = ModalRoute.of(context)?.settings.arguments
        //       as Map<String, dynamic>?;
        //   if (args == null || !args.containsKey('doctorId')) {
        //     return const Scaffold(
        //       body: Center(
        //         child: Text(
        //             'Missing or invalid arguments for doctor schedule page.'),
        //       ),
        //     );
        //   }
        //   return DoctorSchedulePage(doctorId: args['doctorId']);
        // },
        '/staffNotifications': (context) => const StaffNotificationPage(),
        '/doctorNotifications': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          if (args == null || !args.containsKey('doctorId')) {
            return const Scaffold(
              body: Center(
                child: Text(
                    'Missing or invalid arguments for doctor schedule page.'),
              ),
            );
          }
          return DoctorNotificationPage(doctorId: args['doctorId']);
        },
        '/patienthistory': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          if (args == null ||
              !args.containsKey('patientId') ||
              !args.containsKey('doctorId')) {
            return const Scaffold(
              body: Center(
                child: Text(
                    'Missing or invalid arguments for patient history page.'),
              ),
            );
          }
          return PatientHistoryPage(
            patientId: args['patientId'],
            doctorId: args['doctorId'], // ✅ รับ doctorId ที่ถูกส่งมา
          );
        },
        '/medicalRecordList': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          if (args == null || !args.containsKey('doctorId')) {
            return const Scaffold(
              body: Center(
                  child: Text('Invalid arguments for Medical Record page')),
            );
          }
          return MedicalRecordListPage(doctorId: args['doctorId']);
        },
        '/patientAppointments': (context) {
          final args = (ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?) ??
              {};
          return PatientAppointmentListPage(
            patientId: args['patientId'] ?? '', // ✅ ป้องกัน null
            doctorId: args['doctorId'] ?? '', // ✅ ป้องกัน null
          );
        },
        //ของแพทย์
        '/patientMedicalRecord': (context) {
          final args = (ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?) ??
              {};

          return MedicalRecordDetailPage(
            appointmentId: args['appointmentId'] ?? '',
            patientId: args['patientId'] ?? '',
            doctorId: args['doctorId'] ?? '',
            record: null,
          );
        },
        //ของผู้ป่วย
        '/medicalRecordDetail': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;

          if (arguments != null) {
            return PatientMedicalRecordDetailPage(
              appointmentId: arguments['appointmentId'] ?? '',
              patientId: arguments['patientId'] ?? '',
              doctorId: arguments['doctorId'] ?? '',
              record: arguments['record'] ?? {},
            );
          } else {
            return Scaffold(
              appBar: AppBar(title: const Text("Error")),
              body: const Center(child: Text("ไม่พบข้อมูลประวัติการรักษา")),
            );
          }
        },
        '/feedback': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;

          if (arguments != null) {
            return FeedbackPage(
              doctorId: arguments['doctorId'] ?? '',
              appointmentId: arguments['appointmentId'] ?? '',
            );
          } else {
            return Scaffold(
              appBar: AppBar(title: const Text("Error")),
              body: const Center(child: Text("ไม่พบข้อมูลแพทย์")),
            );
          }
        },
        '/doctorsList': (context) => const DoctorsListPage(),
      },
    );
  }
}
