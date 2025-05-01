import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:medibridge_application/models/patient_model.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './../models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthService._internal(); // Private constructor

  String? _staffEmail; // เปลี่ยนเป็นตัวแปรปกติที่สามารถเปลี่ยนค่าได้
  String? _staffPassword;
  // ✅ Getter สำหรับดึงค่า
  String? get staffEmail => _staffEmail;
  String? get staffPassword => _staffPassword;

  // ✅ Setter สำหรับกำหนดค่า (แก้ปัญหาการกำหนดค่าไม่ได้)
  set staffEmail(String? email) {
    _staffEmail = email;
  }

  set staffPassword(String? password) {
    _staffPassword = password;
  }

  String? _fcmToken; // เก็บ FCM Token ไว้ในหน่วยความจำ
  String? get fcmToken => _fcmToken;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final uuid = const Uuid();

  User? get currentUser {
    return _firebaseAuth.currentUser;
  }

  String? get currentUserId {
    return _firebaseAuth.currentUser?.uid;
  }

  // Register User
  Future<void> registerUser(UserModel user, String password) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Firebase User is null');
      }

      String userId = firebaseUser.uid;
      user.userId = userId;

      // ดึง FCM Token
      String? fcmToken = await FirebaseMessaging.instance.getToken() ?? '';

      // บันทึกข้อมูลใน collection "User"
      await _firestore.collection('User').doc(userId).set({
        'user_id': user.userId,
        'first_name': user.firstName,
        'last_name': user.lastName,
        'email': user.email,
        'phone_number': user.phoneNumber,
        'role': user.role,
        'fcm_token': fcmToken.isNotEmpty ? [fcmToken] : [],
        'created_at': FieldValue.serverTimestamp(),
      });

      if (user.role == 'Patient') {
        PatientModel newPatient = PatientModel(
          patientId: user.userId,
          userId: user.userId,
        );
        await _firestore
            .collection('Patients')
            .doc(newPatient.patientId)
            .set(newPatient.toMap());
      }

      debugPrint('✅ User registered successfully in Firestore');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('อีเมลนี้ถูกใช้ไปแล้ว');
      } else {
        throw Exception('เกิดข้อผิดพลาดในการสมัครสมาชิก: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Error registering user: $e');
      throw Exception('Failed to register user');
    }
  }

  Future<void> saveStaffCredentials(String email, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('staffEmail', email);
    await prefs.setString('staffPassword', password);
    _staffEmail = email;
    _staffPassword = password;
    debugPrint(
        '✅ Staff Credentials Saved: Email - $email, Password - [HIDDEN]');
  }

  Future<void> loadStaffCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _staffEmail = prefs.getString('staffEmail');
    _staffPassword = prefs.getString('staffPassword');
    print(
        '🔄 Staff Credentials Loaded: Email - $_staffEmail, Password - [HIDDEN]');
  }

  Future<void> clearStaffCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('staffEmail'); // ลบข้อมูลออกจาก SharedPreferences
    staffEmail = null;
    debugPrint('🔄 Staff Credentials Cleared');
  }

  // Sign in with Email & Password
  Future<User?> signInWithEmailAndPassword(
      String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      final User? user = userCredential.user;

      debugPrint('[MyApp] User logged in: ${user?.uid}');

      if (user != null) {
        // ✅ อัปเดต FCM Token ทันทีหลังจากล็อกอิน
        await saveFcmTokenToFirestore(user.uid);
        debugPrint('[MyApp] User logged in and FCM Token saved: ${user.uid}');

        // ✅ ดึง role ของผู้ใช้จาก Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('User').doc(user.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
          if (data != null) {
            debugPrint('[MyApp] User document data: $data');
            String role = data['role'] ?? 'undefined';
            debugPrint('[MyApp] User role: $role');

            // ✅ ถ้าเป็น Staff -> บันทึก Credentials ลง SharedPreferences
            if (role == 'Staff') {
              staffEmail = email;
              staffPassword = password;
              await saveStaffCredentials(email, password); // บันทึก email ไว้
              debugPrint('✅ Staff login successful. Credentials saved.');
            }
          } else {
            debugPrint(
                '[MyApp] User document data is null for UID: ${user.uid}');
          }
        } else {
          debugPrint(
              '[MyApp] User document does not exist for UID: ${user.uid}');
        }

        // ✅ นำทางไปยังหน้า Home
        debugPrint('[MyApp] Navigating to home with UID: ${user.uid}');
        await navigateToHome(user.uid, context);
      }

      return user;
    } catch (e) {
      debugPrint('[MyApp] Error during Email & Password Sign-In: $e');
      return null;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('🔹 Google Sign-In was cancelled');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint('📌 Current FCM Token: $fcmToken');

        if (fcmToken == null) {
          debugPrint('⚠️ FCM Token is null, skipping update');
          return user;
        }

        debugPrint('[MyApp] Google Sign-In successful');
        debugPrint('[MyApp] User logged in: ${user.uid}');

        // 🔹 อ้างอิงเอกสารของผู้ใช้ใน Firestore
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('User').doc(user.uid);
        DocumentReference patientRef =
            FirebaseFirestore.instance.collection('Patients').doc(user.uid);

        await userRef.get().then((DocumentSnapshot doc) async {
          if (!doc.exists) {
            // 🔹 สร้างเอกสารใน `User`
            await userRef.set({
              'user_id': user.uid,
              'first_name': user.displayName ?? '',
              'last_name': '',
              'email': user.email ?? '',
              'phone_number': '',
              'role': 'Patient',
              'fcm_token': [fcmToken],
            }, SetOptions(merge: true)).then((_) {
              debugPrint('✅ User document created: ${user.uid}');
            }).catchError((error) {
              debugPrint('❌ Error creating user document: $error');
            });

            // 🔹 สร้างเอกสารใน `Patients`
            await patientRef.set({
              'patient_id': user.uid,
              'user_id': user.uid,
              'allergies': '',
              'blood_type': '',
              'chronic_conditions': '',
              'date_of_birth': '',
              'emergency_contact': '',
              'gender': '',
              'height': 0,
              'weight': 0,
            }, SetOptions(merge: true)).then((_) {
              debugPrint('✅ Patient document created: ${user.uid}');
            }).catchError((error) {
              debugPrint('❌ Error creating patient document: $error');
            });
          } else {
            // 🔹 อัปเดต token ใน `User`
            debugPrint('🔹 User already exists, updating FCM Token');
            await userRef.update({
              'fcm_token': FieldValue.arrayUnion([fcmToken]),
            }).then((_) {
              debugPrint('✅ FCM Token updated: ${user.uid}');
            }).catchError((error) {
              debugPrint('❌ Error updating FCM Token: $error');
            });

            // 🔹 ตรวจสอบและสร้าง `Patients` ถ้ายังไม่มี
            await patientRef.get().then((DocumentSnapshot patientDoc) async {
              if (!patientDoc.exists) {
                await patientRef.set({
                  'patient_id': user.uid,
                  'user_id': user.uid,
                  'allergies': '',
                  'blood_type': '',
                  'chronic_conditions': '',
                  'date_of_birth': '',
                  'emergency_contact': '',
                  'gender': '',
                  'height': 0,
                  'weight': 0,
                }, SetOptions(merge: true)).then((_) {
                  debugPrint('✅ Patient document created: ${user.uid}');
                }).catchError((error) {
                  debugPrint('❌ Error creating patient document: $error');
                });
              }
            }).catchError((error) {
              debugPrint('❌ Error checking if patient exists: $error');
            });
          }
        }).catchError((error) {
          debugPrint('❌ Error checking if user exists: $error');
        });

        navigateToHome(user.uid, context);
      }
      return user;
    } catch (e) {
      debugPrint('❌ Error during Google Sign-In: $e');
      return null;
    }
  }

  // Sign In with Facebook
  Future<User?> signInWithFacebook(BuildContext context) async {
    try {
      // ✅ ขอให้ผู้ใช้ล็อกอินด้วย Facebook
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;

        // ✅ ใช้ Token สร้าง Credential
        final OAuthCredential credential =
            FacebookAuthProvider.credential(accessToken.tokenString);

        // ✅ ล็อกอินผ่าน Firebase
        UserCredential userCredential =
            await _firebaseAuth.signInWithCredential(credential);
        final User? user = userCredential.user;

        if (user != null) {
          // ✅ ดึง FCM Token
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          debugPrint('📌 Current FCM Token: $fcmToken');

          if (fcmToken == null) {
            debugPrint('⚠️ FCM Token is null, skipping update');
            return user;
          }

          debugPrint('[MyApp] Facebook Sign-In successful');
          debugPrint('[MyApp] User logged in: ${user.uid}');

          // 🔹 อ้างอิงเอกสารของผู้ใช้ใน Firestore
          DocumentReference userRef =
              _firestore.collection('User').doc(user.uid);
          DocumentReference patientRef =
              _firestore.collection('Patients').doc(user.uid);

          await userRef.get().then((DocumentSnapshot doc) async {
            if (!doc.exists) {
              // 🔹 สร้างเอกสารใน `User`
              await userRef.set({
                'user_id': user.uid,
                'first_name': user.displayName ?? '',
                'last_name': '',
                'email': user.email ?? '',
                'phone_number': '',
                'role': 'Patient',
                'fcm_token': [fcmToken],
              }, SetOptions(merge: true)).then((_) {
                debugPrint('✅ User document created: ${user.uid}');
              }).catchError((error) {
                debugPrint('❌ Error creating user document: $error');
              });

              // 🔹 สร้างเอกสารใน `Patients`
              await patientRef.set({
                'patient_id': user.uid,
                'user_id': user.uid,
                'allergies': '',
                'blood_type': '',
                'chronic_conditions': '',
                'date_of_birth': '',
                'emergency_contact': '',
                'gender': '',
                'height': 0,
                'weight': 0,
              }, SetOptions(merge: true)).then((_) {
                debugPrint('✅ Patient document created: ${user.uid}');
              }).catchError((error) {
                debugPrint('❌ Error creating patient document: $error');
              });
            } else {
              // 🔹 อัปเดต token ใน `User`
              debugPrint('🔹 User already exists, updating FCM Token');
              await userRef.update({
                'fcm_token': FieldValue.arrayUnion([fcmToken]),
              }).then((_) {
                debugPrint('✅ FCM Token updated: ${user.uid}');
              }).catchError((error) {
                debugPrint('❌ Error updating FCM Token: $error');
              });

              // 🔹 ตรวจสอบและสร้าง `Patients` ถ้ายังไม่มี
              await patientRef.get().then((DocumentSnapshot patientDoc) async {
                if (!patientDoc.exists) {
                  await patientRef.set({
                    'patient_id': user.uid,
                    'user_id': user.uid,
                    'allergies': '',
                    'blood_type': '',
                    'chronic_conditions': '',
                    'date_of_birth': '',
                    'emergency_contact': '',
                    'gender': '',
                    'height': 0,
                    'weight': 0,
                  }, SetOptions(merge: true)).then((_) {
                    debugPrint('✅ Patient document created: ${user.uid}');
                  }).catchError((error) {
                    debugPrint('❌ Error creating patient document: $error');
                  });
                }
              }).catchError((error) {
                debugPrint('❌ Error checking if patient exists: $error');
              });
            }
          }).catchError((error) {
            debugPrint('❌ Error checking if user exists: $error');
          });

          // ✅ นำทางไปหน้า Home
          navigateToHome(user.uid, context);
        }
        return user;
      } else {
        debugPrint('❌ Facebook Sign-In failed: ${result.status}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error during Facebook Sign-In: $e');
      return null;
    }
  }

  // Forgot Password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } catch (e) {
      return e.toString(); // Return error message
    }
  }

  // Navigate to Home based on Role
  Future<void> navigateToHome(String userId, BuildContext context) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('User').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String role = userData['role'] ?? 'undefined';

        if (role == 'Doctor') {
          Navigator.pushReplacementNamed(context, '/doctorHome', arguments: {
            'doctorId': userId,
          });
        } else if (role == 'Patient') {
          Navigator.pushReplacementNamed(context, '/patientHome');
        } else if (role == 'Staff') {
          Navigator.pushReplacementNamed(context, '/staffHome');
        } else {
          print('Unknown role: $role');
        }
      } else {
        print('User document is null or does not exist.');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Error navigating to home: $e');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Update User
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('User').doc(userId).update(updates);
      print('User updated successfully');
    } catch (e) {
      print('Error updating user: $e');
      throw Exception('Failed to update user');
    }
  }

  // Delete User
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('User').doc(userId).delete();
      print('✅ User deleted successfully');
    } catch (e) {
      print('❌ Error deleting user: $e');
      throw Exception('Failed to delete user');
    }
  }

  // Search Users
  Future<List<UserModel>> searchUsers({
    String? nameQuery,
    String? roleQuery,
  }) async {
    try {
      Query query = _firestore.collection('User');
      if (nameQuery != null && nameQuery.isNotEmpty) {
        query = query
            .where('first_name', isGreaterThanOrEqualTo: nameQuery)
            .where('first_name', isLessThanOrEqualTo: nameQuery + '\uf8ff');
      }
      if (roleQuery != null && roleQuery.isNotEmpty) {
        query = query.where('role', isEqualTo: roleQuery);
      }

      QuerySnapshot snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      throw Exception('Failed to search users');
    }
  }

  Future<List<UserModel>> searchUsersByNameAndRole({
    String? nameQuery,
    String? roleQuery,
  }) async {
    try {
      Query query = _firestore.collection('User');

      // กรองบทบาทตามที่เลือก ถ้ามีการระบุ roleQuery
      if (roleQuery != null && roleQuery.isNotEmpty) {
        query = query.where('role', isEqualTo: roleQuery);
      } else {
        // ถ้าไม่ได้เลือก filter role ให้ดึงเฉพาะ Doctor และ Staff
        query = query.where('role', whereIn: ['Doctor', 'Staff']);
      }

      // กรองชื่อ
      if (nameQuery != null && nameQuery.isNotEmpty) {
        query = query
            .where('first_name', isGreaterThanOrEqualTo: nameQuery)
            .where('first_name', isLessThanOrEqualTo: nameQuery + '\uf8ff');
      }

      QuerySnapshot snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      throw Exception('Failed to search users');
    }
  }

  Future<void> addDoctorToCollection(String userId,
      {Map<String, dynamic>? updates}) async {
    try {
      if (updates != null && updates.isNotEmpty) {
        await _firestore.collection('Doctors').doc(userId).set(
              updates,
              SetOptions(merge: true),
            );
      } else {
        await _firestore.collection('Doctors').doc(userId).set({
          'doctor_id': userId,
          'user_id': userId,
          'specialty': '',
          'schedule': [],
          'available_days': [],
          'available_hours': {'start': '', 'end': ''},
          'education': '',
        });
      }
      print('Doctor added or updated successfully');
    } catch (e) {
      print('Error adding or updating doctor: $e');
      throw Exception('Failed to add or update doctor');
    }
  }

  Future<UserModel?> getStaffProfile(String userId) async {
    try {
      // ดึงเอกสารจากคอลเลกชัน User ตาม userId
      DocumentSnapshot userDoc =
          await _firestore.collection('User').doc(userId).get();

      if (userDoc.exists) {
        // แปลงข้อมูลจาก Firestore เป็น UserModel
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      } else {
        print('User not found');
        return null;
      }
    } catch (e) {
      print('Error getting staff profile: $e');
      return null;
    }
  }

  Future<void> reLogin() async {
    if (_staffEmail != null && _staffPassword != null) {
      try {
        await _firebaseAuth.signInWithEmailAndPassword(
          email: _staffEmail!,
          password: _staffPassword!,
        );
        debugPrint('✅ Re-login successful');
      } catch (e) {
        debugPrint('❌ Error during re-login: $e');
      }
    } else {
      debugPrint('❌ Error: Staff credentials are missing');
    }
  }

  Future<void> staffLogin(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);

      // ✅ ใช้ Setter เพื่อกำหนดค่าให้กับ Staff Email และ Password
      staffEmail = email;
      staffPassword = password;

      print('✅ Staff login successful. Credentials saved');
    } catch (e) {
      print('❌ Error logging in: $e');
    }
  }

  Future<void> saveFcmTokenToFirestore(String userId) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    String? fcmToken = await messaging.getToken();
    if (fcmToken != null) {
      await FirebaseFirestore.instance.collection('User').doc(userId).update({
        'fcm_token': FieldValue.arrayUnion([fcmToken])
      });
      print("✅ FCM Token บันทึกเรียบร้อย: $fcmToken");
    } else {
      print("❌ ไม่สามารถดึง FCM Token ได้");
    }
  }

  //ไฟล์นี้จัดการเกี่ยวกับการ Authentication, เช่น การล็อกอิน, การลงทะเบียน, และการอัปเดต FCM Token
  Future<void> updateUserFcmToken(String userId, [String? newFcmToken]) async {
    try {
      String? fcmToken =
          newFcmToken ?? await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        await FirebaseFirestore.instance.collection('User').doc(userId).update({
          'fcm_token': FieldValue.arrayUnion([fcmToken]),
        });
        debugPrint('✅ FCM Token updated in Firestore for user: $userId');
      } else {
        debugPrint('⚠️ Failed to get FCM Token');
      }
    } catch (e) {
      debugPrint('❌ Error updating FCM Token: $e');
    }
  }

  void listenForFcmTokenChanges() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newFcmToken) async {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await updateUserFcmToken(userId, newFcmToken);
        debugPrint(
            "🔄 FCM Token refreshed and updated in Firestore: $newFcmToken");
      }
    });
  }
}
