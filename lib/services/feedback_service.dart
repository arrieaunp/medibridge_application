import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitOrUpdateFeedback({
    required String doctorId,
    required String appointmentId,
    required int rating,
    required String comment,
  }) async {
    if (doctorId.isEmpty || appointmentId.isEmpty) {
      throw Exception("Doctor ID or Appointment ID is empty!");
    }

    try {
      DocumentReference doctorRef =
          _firestore.collection('Doctors').doc(doctorId);

      await doctorRef.set({
        'feedbacks': {
          appointmentId: {
            'rating': rating,
            'comment': comment,
            'timestamp': Timestamp.now(),
          }
        }
      }, SetOptions(merge: true)); // ✅ ใช้ merge เพื่อไม่เขียนทับข้อมูลเดิม
    } catch (e) {
      throw Exception("Error submitting feedback: $e");
    }
  }

  Future<Map<String, dynamic>?> getFeedback({
    required String doctorId,
    required String appointmentId,
  }) async {
    DocumentSnapshot doctorDoc =
        await _firestore.collection('Doctors').doc(doctorId).get();

    if (doctorDoc.exists) {
      var data = doctorDoc.data() as Map<String, dynamic>;
      var feedbacks = data['feedbacks'] as Map<String, dynamic>?;

      if (feedbacks != null && feedbacks.containsKey(appointmentId)) {
        return feedbacks[appointmentId];
      }
    }

    return null; // ✅ ไม่มีฟีดแบคของ appointment นี้
  }
}
