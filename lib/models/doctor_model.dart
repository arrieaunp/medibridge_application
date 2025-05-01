class DoctorModel {
  final String doctorId;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String specialization;
  final String education;
  final List<String> availableDays;
  final Map<String, String> availableHours;
  final List<Map<String, dynamic>> feedbacks;

  DoctorModel({
    required this.doctorId,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.specialization,
    required this.education,
    required this.availableDays,
    required this.availableHours,
    this.feedbacks = const [], 
  });

  factory DoctorModel.fromFirestore(Map<String, dynamic> data) {
    return DoctorModel(
      doctorId: data['doctor_id'],
      firstName: data['first_name'],
      lastName: data['last_name'],
      phoneNumber: data['phone_number'],
      specialization: data['specialization'],
      education: data['education'],
      availableDays: List<String>.from(data['available_days']),
      availableHours: Map<String, String>.from(data['available_hours']),
      feedbacks: List<Map<String, dynamic>>.from(data['feedbacks'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'doctor_id': doctorId,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'specialization': specialization,
      'education': education,
      'available_days': availableDays,
      'available_hours': availableHours,
      'feedbacks': feedbacks,
    };
  }
}
