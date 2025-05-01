import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Message;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:medibridge_application/main.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupFlutterNotification();
  await NotificationService.instance.showNotification(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  factory NotificationService() => instance;

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isFlutterLocalNotificationsInitialized = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String baseUrl = 'http://172.20.10.2:5001';

  Future<void> initialize(BuildContext context) async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await _setupMessageHandlers(context);

    // ✅ แสดงแจ้งเตือนขณะแอปทำงาน
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🚀 [onMessage] Notification: ${message.notification?.title}');
      print('📩 [onMessage] Body: ${message.notification?.body}');

      showNotification(message);
    });

    // Get FCM token
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      await sendTokenToBackend(token);
    }

    // ✅ เพิ่ม listener ขณะเปิดแอป
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          '🚨 [onMessage] ได้รับข้อความ: ${message.notification?.title}');
      debugPrint('💬 [onMessage] Body: ${message.notification?.body}');
      debugPrint('🗂️ [onMessage] Data: ${message.data}');
      showNotification(message);
    });

    FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
      debugPrint(
          '🚨 [onBackgroundMessage] ได้รับข้อความ: ${message.notification?.title}');
      debugPrint(
          '💬 [onBackgroundMessage] Body: ${message.notification?.body}');
      debugPrint('🗂️ [onBackgroundMessage] Data: ${message.data}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
          '🚀 [onMessageOpenedApp] คลิกแจ้งเตือน: ${message.notification?.title}');
      debugPrint('💬 [onMessageOpenedApp] Body: ${message.notification?.body}');
      debugPrint('🗂️ [onMessageOpenedApp] Data: ${message.data}');
    });
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    print('Permission status: ${settings.authorizationStatus}');
  }

  Future<void> setupFlutterNotification() async {
    if (_isFlutterLocalNotificationsInitialized) {
      return;
    }

    // android setup
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notification',
      description: 'used foe importance noti',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initializtionSettingAndroid =
        AndroidInitializationSettings('@mipmap/ic_lancher');

    final initializationSettings = const InitializationSettings(
      android: initializtionSettingAndroid,
    );

    //flutter nofi setup
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse: (details) {},
    );
    _isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
    debugPrint('📲 [showNotification] กำลังแสดงการแจ้งเตือน...');
    debugPrint('📝 Title: ${message.notification?.title}');
    debugPrint('📝 Body: ${message.notification?.body}');
    debugPrint('📦 Data: ${message.data}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification == null) {
      debugPrint('⚠️ [showNotification] ไม่มีข้อมูล notification จาก FCM');
    }

    if (notification != null && android != null) {
      debugPrint('✅ [showNotification] กำลังเรียก _localNotifications.show()');
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'ช่องสำหรับแจ้งเตือนสำคัญ',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(notification.body ?? ''),
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } else {
      debugPrint('⚠️ [showNotification] ไม่สามารถแสดงการแจ้งเตือนได้');
    }
  }

  Future<void> _setupMessageHandlers(BuildContext context) async {
    FirebaseMessaging.onMessage.listen((message) {
      // ตรวจสอบว่าอยู่ในหน้า staff_notification หรือไม่
      if (ModalRoute.of(context)?.settings.name == '/staff_notification') {
        // หากอยู่ในหน้า staff_notification ให้ refresh ข้อมูล
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('มีการแจ้งเตือนใหม่: ${message.notification?.title}')),
        );
        // คุณสามารถใช้ State Management เพื่อ refresh รายการแจ้งเตือนในหน้า staff_notification
      } else {
        // หากอยู่นอกหน้า staff_notification ให้แสดงการแจ้งเตือนปกติ

        showNotification(message);
      }
    });

    // เมื่อผู้ใช้คลิกที่แจ้งเตือน (background หรือ terminated state)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data.containsKey('appointment_id')) {
        // เปิดหน้าสำหรับยืนยันหรือยกเลิกนัดหมาย
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!.pushNamed('/appointmentManagement');
          }
        });
      }
    });

    // เมื่อเปิดแอปครั้งแรกจากแจ้งเตือน
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage, context);
    }
  }

  Future<void> sendTokenToBackend(String token) async {
    final url = Uri.parse('https://your-backend-api.com/save-fcm-token');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fcm_token': token}),
    );

    if (response.statusCode == 200) {
      debugPrint('FCM token sent successfully');
    } else {
      debugPrint('Failed to send FCM token');
    }
  }

  void _handleBackgroundMessage(RemoteMessage message, BuildContext context) {
    final data = message.data;

    if (data.containsKey('appointment_id')) {
      final appointmentId = data['appointment_id'];
      // ใช้ Navigator เพื่อเปิดหน้าที่เหมาะสม
      Navigator.pushNamed(context, '/appointmentManagement',
          arguments: {'appointmentId': appointmentId});
    }
  }

  Future<void> sendNewAppointmentNotification(String appointmentId,
      DateTime? appointmentDate, String? appointmentTime) async {
    try {
      // ✅ แก้ไขเพื่อความชัดเจน
      String formattedDate = appointmentDate != null
          ? _formatDate(appointmentDate)
          : 'ไม่ระบุวันที่';
      String formattedTime = appointmentTime ?? 'ไม่ระบุเวลา';

      debugPrint(
          '📅 Sending notification: Date=$formattedDate, Time=$formattedTime');

      final url =
          Uri.parse('http://172.20.10.2:5001/new-appointment-notification');

      final payload = jsonEncode({
        'appointment_id': appointmentId,
        'title': '🔔 แจ้งเตือน: นัดหมายใหม่',
        'body':
            'มีนัดหมายใหม่ วันที่ $formattedDate เวลา $formattedTime กรุณาตรวจสอบ',
      });

      debugPrint('📡 Payload: $payload');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );

      if (response.statusCode == 200) {
        debugPrint("✅ ส่งแจ้งเตือนสำเร็จ: ${response.body}");
      } else {
        debugPrint(
            "❌ ส่งแจ้งเตือนล้มเหลว: ${response.statusCode} -> ${response.body}");
      }
    } catch (e) {
      debugPrint('❌ Error sending notification to staff: $e');
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'ไม่ระบุวันที่';
    try {
      final formatted = '${date.day}/${date.month}/${date.year}';
      debugPrint('📆 Formatted date: $formatted');
      return formatted;
    } catch (e) {
      debugPrint('❌ Error formatting date: $e');
      return 'ไม่ระบุวันที่';
    }
  }

// 🔔 ส่งแจ้งเตือนค่ารักษาพยาบาลให้ผู้ป่วย (ไม่มี due_date)
Future<void> sendPaymentDueNotificationToPatient({
  required String patientId,
  required double amount,
}) async {
  try {
    // ✅ ดึงอีเมลของ **ผู้ป่วย** จาก Firestore
    DocumentSnapshot patientSnapshot =
        await _firestore.collection('User').doc(patientId).get();

    if (!patientSnapshot.exists) {
      throw Exception('❌ ไม่พบข้อมูลผู้ป่วยใน Firestore');
    }

    String patientEmail = patientSnapshot['email'];
    String patientName = patientSnapshot['first_name'] ?? 'ไม่ระบุชื่อ';

    // ✅ **สร้างข้อความแจ้งเตือนผ่าน Firebase Cloud Messaging (FCM)**
    String fcmMessage =
        "คุณมีค่ารักษาพยาบาลจำนวน $amount บาท กรุณาชำระเงินโดยเร็วที่สุด";

    // 🚀 สร้าง Payload สำหรับ Firebase Cloud Messaging
    final payload = jsonEncode({
      'patient_id': patientId,
      'amount': amount,
      'title': '💳 แจ้งเตือนค่ารักษาพยาบาล',
      'body': fcmMessage,
    });

    // 🌐 **ส่งแจ้งเตือนผ่าน FCM**
    final response = await http.post(
      Uri.parse('$baseUrl/payment-due-notification'),
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );

    if (response.statusCode == 200) {
      debugPrint('✅ ส่งแจ้งเตือนค่ารักษาพยาบาลถึงผู้ป่วยสำเร็จ');
    } else {
      debugPrint(
          '❌ แจ้งเตือนผู้ป่วยล้มเหลว: ${response.statusCode} -> ${response.body}');
    }

    // ✅ **สร้างข้อความอีเมลแจ้งเตือนผู้ป่วย**
    String emailSubject = '💳 แจ้งเตือนค่ารักษาพยาบาล';
    String emailBody =
        'เรียนคุณ $patientName,\n\n'
        'ท่านมีค่ารักษาพยาบาลจำนวน **$amount บาท** ที่ต้องชำระ.\n\n'
        'กรุณาชำระเงินผ่านระบบ MediBridge เพื่อดำเนินการนัดหมายของท่านต่อไป.\n\n'
        'หากท่านมีข้อสงสัย สามารถติดต่อเจ้าหน้าที่ได้โดยตรง.\n\n'
        'ขอบคุณที่ใช้บริการ MediBridge\n'
        'ทีมงาน MediBridge';

    // ✅ **ส่งอีเมลแจ้งเตือนผู้ป่วย**
    await NotificationService.instance.sendEmailNotification(
      toEmail: patientEmail,
      subject: emailSubject,
      body: emailBody,
    );

    debugPrint('✅ ส่งอีเมลแจ้งเตือนให้ผู้ป่วยสำเร็จ');
  } catch (e) {
    debugPrint('❌ Error sending payment due notification: $e');
  }
}

    Future<void> sendEmailNotification({
    required String toEmail,
    required String subject,
    required String body,
  }) async {
    final String username = dotenv.env['EMAIL_USERNAME']!;
    final String password = dotenv.env['EMAIL_PASSWORD']!;

    final smtpServer = gmail(username, password); // ใช้ Gmail SMTP Server

    final message = Message()
      ..from = Address(username, 'MediBridge')
      ..recipients.add(toEmail)
      ..subject = subject
      ..text = body;

    try {
      final sendReport = await send(message, smtpServer);
      print('✅ Email sent: ${sendReport.toString()}');
    } catch (e) {
      print('❌ Error sending email: $e');
    }
  }

}
