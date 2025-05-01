import 'package:medibridge_application/models/patient_model.dart';

import '../services/auth_service.dart';
import './../models/user_model.dart';
import 'package:uuid/uuid.dart';

class AuthController {
  final AuthService _authService = AuthService();
  final uuid = const Uuid();

  // Function to register a new user
Future<void> registerNewUser({
  required String firstName,
  required String lastName,
  required String phoneNumber,
  required String email,
  required String password,
}) async {
  // กำหนด role เป็น 'Patient' เสมอ (เพราะมาจากหน้าลงทะเบียนผู้ป่วย)
  String role = 'Patient';

  // สร้าง UserModel (userId จะถูกเซตอีกทีใน auth_service)
  UserModel newUser = UserModel(
    userId: '', 
    firstName: firstName,
    lastName: lastName,
    phoneNumber: phoneNumber,
    email: email,
    role: role,
  );

  // เรียกไปที่ auth_service เพื่อทำการสมัครและบันทึกใน Firestore
  await _authService.registerUser(newUser, password);
}


}
