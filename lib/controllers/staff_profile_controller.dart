import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StaffProfileController {
  final FirebaseAuth _auth = FirebaseAuth.instance; // สำหรับการดึงข้อมูลผู้ใช้ที่ล็อกอิน
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Getter สำหรับดึง userId ของผู้ใช้ที่ล็อกอิน
  String? get currentUserId {
    return _auth.currentUser?.uid;
  }

  Future<Map<String, dynamic>?> loadUserData() async {
    try {
      String userId = currentUserId!;
      DocumentSnapshot userDoc =
          await _firestore.collection('User').doc(userId).get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      throw Exception('Failed to load user data');
    }
    return null;
  }

  Future<String> uploadProfilePicture(File image) async {
    try {
      String userId = currentUserId!;
      String fileName = 'profile_pictures/$userId.jpg';
      Reference storageRef = _storage.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Failed to upload image');
    }
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      String userId = currentUserId!;
      await _firestore.collection('User').doc(userId).update(data);
    } catch (e) {
      debugPrint('Error updating user data: $e');
      throw Exception('Failed to update user data');
    }
  }
}
