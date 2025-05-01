import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medibridge_application/controllers/doctor_profile_controller.dart';
import 'package:medibridge_application/utils/signout.dart';
import 'package:medibridge_application/widgets/available_days_dropdown.dart';
import 'package:medibridge_application/widgets/doc_main_layout.dart';

class DoctorProfilePage extends StatefulWidget {
  final String doctorId;

  const DoctorProfilePage({Key? key, required this.doctorId}) : super(key: key);

  @override
  _DoctorProfilePageState createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  String? firstName;
  String? lastName;
  String? phoneNumber;
  String? profilePicUrl;
  String? specialization;
  String? education;
  String? startTime;
  String? endTime;
  List<String> selectedDays = [];
  bool isLoading = false;
  File? _image;

  final DoctorProfileController _controller = DoctorProfileController();
  late Future<Map<String, dynamic>> _doctorFuture;

  @override
  void initState() {
    super.initState();
    print('Doctor ID in initState: ${widget.doctorId}');
    _doctorFuture = _controller.fetchDoctorProfile(widget.doctorId);
  }

  Future<void> _updateDoctorData() async {
    try {
      Map<String, dynamic> data = {
        'user': {
          'first_name': firstName ?? '',
          'last_name': lastName ?? '',
          'phone_number': phoneNumber ?? '',
          'profile_pic': profilePicUrl ?? '',
        },
        'doctor': {
          'available_days':
              selectedDays.isNotEmpty ? selectedDays : ['ไม่มีข้อมูล'],
          'available_hours': {
            'start': startTime ?? '00:00',
            'end': endTime ?? '00:00',
          },
          'specialization': specialization ?? 'ไม่มีข้อมูล',
          'education': education ?? 'ไม่มีข้อมูล',
        },
      };

      print('Doctor ID for update: ${widget.doctorId}');
      print('Data to update: $data');

      await _controller.updateDoctorData(widget.doctorId, data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile Updated Successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to Update Profile: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });

        // อัปโหลดรูปภาพ
        String downloadUrl =
            await _controller.uploadProfilePicture(_image!, widget.doctorId);

        print('Uploaded file URL: $downloadUrl');

        // อัปเดตเฉพาะฟิลด์รูปภาพใน Firestore
        await _controller.updateDoctorData(widget.doctorId, {
          'user': {'profile_pic': downloadUrl}
        });

        setState(() {
          profilePicUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปโหลดรูปโปรไฟล์สำเร็จ')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลดรูป: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DocMainLayout(
      selectedIndex: 3,
      doctorId: widget.doctorId,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF3B83F6),
          title: Text(
            'Profile',
            style: GoogleFonts.prompt(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () => showLogoutConfirmationDialog(context),
            ),
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _doctorFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null) {
              return const Center(
                child: Text('Error loading profile or profile not found'),
              );
            }

            final userData = snapshot.data!['user'];
            final doctorData = snapshot.data!['doctor'];

            // Set initial values
            firstName ??= userData['first_name'];
            lastName ??= userData['last_name'];
            phoneNumber ??= userData['phone_number'];
            profilePicUrl ??= userData['profile_pic'];
            specialization ??= doctorData['specialization'];
            education ??= doctorData['education'];
            startTime ??= doctorData['available_hours']['start'];
            endTime ??= doctorData['available_hours']['end'];
            if (selectedDays.isEmpty && doctorData['available_days'] != null) {
              selectedDays = List<String>.from(doctorData['available_days']);
            }

            return SingleChildScrollView(
              padding: EdgeInsets.zero, // กำหนด Padding เป็น 0
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        color: const Color(0xFF3B83F6),
                        height: 100,
                      ),
                      Positioned(
                        top: 50,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: _pickImage, // เรียกใช้งานฟังก์ชันเลือกรูป
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: profilePicUrl != null &&
                                      profilePicUrl!.isNotEmpty
                                  ? NetworkImage(profilePicUrl!)
                                      as ImageProvider
                                  : const AssetImage(
                                      'assets/images/default_profile.png'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child:
                            _buildTextField('First Name', firstName, (value) {
                          firstName = value;
                        }),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField('Last Name', lastName, (value) {
                          lastName = value;
                        }),
                      ),
                    ],
                  ),
                  _buildTextField('Phone Number', phoneNumber, (value) {
                    phoneNumber = value;
                  }),
                  _buildTextField(
                    'อีเมล',
                    userData['email'] ?? '',
                    null,
                    enabled: false,
                  ),
                  _buildTextField('Specialization', specialization, (value) {
                    specialization = value;
                  }),
                  _buildTextField('Education', education, (value) {
                    education = value;
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical:
                            8.0), // กำหนด Padding รอบ AvailableDaysDropdown
                    child: AvailableDaysDropdown(
                      selectedDays: selectedDays,
                      onDaysSelected: (days) {
                        setState(() {
                          selectedDays = days;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child:
                            _buildTextField('Start Time', startTime, (value) {
                          startTime = value;
                        }),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField('End Time', endTime, (value) {
                          endTime = value;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updateDoctorData,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 75, vertical: 15),
                      backgroundColor: const Color(0xFF3B83F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'บันทึก',
                      style: GoogleFonts.prompt(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, String? initialValue, Function(String)? onChanged,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16.0, vertical: 8.0), // กำหนด Padding รอบนอก
      child: TextFormField(
        initialValue: initialValue,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        style: GoogleFonts.prompt(),
        onChanged: onChanged,
      ),
    );
  }
}
