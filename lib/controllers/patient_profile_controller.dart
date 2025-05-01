import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:flutter/material.dart';

class ProfileController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<Map<String, dynamic>?> loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('User').doc(user.uid).get();
        DocumentSnapshot patientDoc =
            await _firestore.collection('Patients').doc(user.uid).get();

        if (userDoc.exists && patientDoc.exists) {
          return {
            'user': userDoc.data(),
            'patient': patientDoc.data(),
          };
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
    return null;
  }

  Future<void> uploadImage(File image) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        String fileName = 'profile_pics/${user.uid}.jpg';
        Reference ref = _storage.ref().child(fileName);
        UploadTask uploadTask = ref.putFile(image);

        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        await _firestore.collection('User').doc(user.uid).update({
          'profile_pic': downloadUrl,
        });
      }
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      throw Exception('Failed to upload profile picture');
    }
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('User').doc(user.uid).update(data['user']);
        await _firestore
            .collection('Patients')
            .doc(user.uid)
            .update(data['patient']);
      }
    } catch (e) {
      debugPrint('Error updating user data: $e');
      throw Exception('Failed to update user data');
    }
  }

  Future<bool> canEditProfilePicture() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return user.providerData.first.providerId != 'google.com';
    }
    return false;
  }
}
