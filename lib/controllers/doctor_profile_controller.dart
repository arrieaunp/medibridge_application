import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class DoctorProfileController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<Map<String, dynamic>> fetchDoctorProfile(String userId) async {
    debugPrint('Fetching User Data for ID: $userId');
    final userSnapshot = await _firestore.collection('User').doc(userId).get();

    if (!userSnapshot.exists) {
      debugPrint('User not found for ID: $userId');
      throw Exception('User not found');
    }

    final userData = userSnapshot.data();
    debugPrint('User Data: $userData');

    debugPrint('Fetching Doctor Data for User ID: $userId');
    final doctorQuery = await _firestore
        .collection('Doctors')
        .where('user_id', isEqualTo: userId)
        .get();

    if (doctorQuery.docs.isEmpty) {
      debugPrint('Doctor data not found for user ID: $userId');
      throw Exception('Doctor data not found');
    }

    final doctorData = doctorQuery.docs.first.data();
    debugPrint('Doctor Data: $doctorData');

    return {
      'user': userData,
      'doctor': doctorData,
    };
  }

  Future<void> updateDoctorData(
      String doctorId, Map<String, dynamic> data) async {
    try {
      if (data.containsKey('user') && data['user'] is Map<String, dynamic>) {
        debugPrint('Updating User Data: ${data['user']}');
        await _firestore.collection('User').doc(doctorId).update(data['user']);
      } else {
        debugPrint('User data is invalid or null: ${data['user']}');
        throw Exception('User data is invalid or null');
      }

      if (data.containsKey('doctor') &&
          data['doctor'] is Map<String, dynamic>) {
        debugPrint('Updating Doctor Data: ${data['doctor']}');
        final doctorQuery = await _firestore
            .collection('Doctors')
            .where('user_id', isEqualTo: doctorId)
            .get();

        debugPrint('Doctor Query Result: ${doctorQuery.docs}');
        if (doctorQuery.docs.isNotEmpty) {
          await _firestore
              .collection('Doctors')
              .doc(doctorQuery.docs.first.id)
              .update(data['doctor']);
        } else {
          debugPrint('Doctor document not found for user ID: $doctorId');
          throw Exception('Doctor document not found');
        }
      }
    } catch (e) {
      debugPrint('Error updating data: $e');
      throw Exception('Error updating doctor data: $e');
    }
  }

  // ฟังก์ชันอัปโหลดรูปไปที่ Firebase Storage
  Future<String> uploadProfilePicture(File image, String doctorId) async {
    try {
      // สร้างชื่อไฟล์และโฟลเดอร์ที่ต้องการจัดเก็บ
      String fileName = 'doc_profile_pic/$doctorId.jpg';
      Reference storageRef = _storage.ref().child(fileName);

      // อัปโหลดไฟล์ไปยัง Firebase Storage
      UploadTask uploadTask = storageRef.putFile(image);
      TaskSnapshot snapshot = await uploadTask;

      // ดึง URL ของรูปภาพที่อัปโหลดสำเร็จ
      String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Upload successful. File URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Failed to upload image');
    }
  }
}
