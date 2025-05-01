class UserModel {
  String userId;
  String firstName;
  String lastName;
  String email;
  String phoneNumber;
  String role;
  List<String> fcmToken;

  UserModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.fcmToken = const [], // ค่าเริ่มต้นเป็น List ว่าง
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'role': role,
      'fcm_token': fcmToken,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['user_id'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      role: map['role'] ?? '',
      fcmToken:
          List<String>.from(map['fcm_token'] ?? []), // แปลงเป็น List<String>
    );
  }

  Future<void> addFcmToken(String newToken) async {
  if (!fcmToken.contains(newToken)) {
    fcmToken.add(newToken); // เพิ่ม Token ใหม่ใน List
  }
}
}
