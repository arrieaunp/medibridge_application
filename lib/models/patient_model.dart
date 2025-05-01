class PatientModel {
  String patientId;
  String userId;
  String dateOfBirth;
  String gender;
  String bloodType;
  String allergies;
  String chronicConditions;
  String emergencyContact;
  int height;
  int weight;
  
  PatientModel({
    required this.patientId,
    required this.userId,
    this.dateOfBirth = '',
    this.gender = 'ชาย',
    this.bloodType = 'A',
    this.allergies = '',
    this.chronicConditions = '',
    this.emergencyContact = '',
    this.height = 0,
    this.weight = 0
  });

  Map<String, dynamic> toMap() {
    return {
      'patient_id': patientId,
      'user_id': userId,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'blood_type': bloodType,
      'allergies': allergies,
      'chronic_conditions': chronicConditions,
      'emergency_contact': emergencyContact,
      'height': height,
      'weight': weight,
    };
  }

    factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      patientId: map['patient_id'] ?? '',
      userId: map['user_id'] ?? '',
      dateOfBirth: map['date_of_birth'] ?? '',
      gender: map['gender'] ?? '',
      bloodType: map['blood_type'] ?? '',
      allergies: map['allergies'] ?? '',
      chronicConditions: map['chronic_conditions'] ?? '',
      emergencyContact: map['emergency_contact'] ?? '',
      height: map['height'] ?? 0,
      weight: map['weight'] ?? 0,
    );
  }

}
