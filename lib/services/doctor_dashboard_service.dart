import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorDashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchFeedbacks(String doctorId) async {
    final doc = await _firestore.collection('Doctors').doc(doctorId).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data.containsKey('feedbacks')) {
        List feedbackList = data['feedbacks'].values.toList();
        return feedbackList.map((fb) => {
          'comment': fb['comment'],
          'rating': fb['rating']?.toDouble() ?? 0.0,
        }).toList();
      }
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchAppointments(String doctorId) async {
    final querySnapshot = await _firestore
        .collection('Appointments')
        .where('doctor_id', isEqualTo: doctorId)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'date': (data['appointment_date'] as Timestamp).toDate(),
        'payment_amount': (data['payment_amount'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList();
  }
}
