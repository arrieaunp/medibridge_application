class PrescriptionModel {
  String name;
  String quantity;
  String frequency;

  PrescriptionModel({
    required this.name,
    required this.quantity,
    required this.frequency,
  });

  // ✅ แปลงจาก Firestore -> PrescriptionModel
  factory PrescriptionModel.fromMap(Map<String, dynamic> data) {
    return PrescriptionModel(
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? '',
      frequency: data['frequency'] ?? '',
    );
  }

  // ✅ แปลงจาก PrescriptionModel -> Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'frequency': frequency,
    };
  }
}
