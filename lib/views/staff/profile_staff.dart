import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medibridge_application/controllers/staff_profile_controller.dart';
import 'package:medibridge_application/widgets/staff_main_layout.dart';
import './../../utils/signout.dart';

class StaffProfilePage extends StatefulWidget {
  const StaffProfilePage({Key? key}) : super(key: key);

  @override
  _StaffProfilePageState createState() => _StaffProfilePageState();
}

class _StaffProfilePageState extends State<StaffProfilePage> {
final StaffProfileController _profileController = StaffProfileController();

  String? firstName;
  String? lastName;
  String? phoneNumber;
  String? email;
  String? profilePicUrl;
  File? _image;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
  setState(() {
    isLoading = true;
  });

  try {
    final userData = await _profileController.loadUserData(); // โหลดข้อมูลของผู้ใช้ที่ล็อกอินอยู่
    if (userData != null) {
      setState(() {
        firstName = userData['first_name'];
        lastName = userData['last_name'];
        phoneNumber = userData['phone_number'];
        email = userData['email'];
        profilePicUrl = userData['profile_pic'] ?? '';
      });
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล')),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
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

        // อัปโหลดรูปภาพไปยัง Firebase Storage
        String downloadUrl = await _profileController.uploadProfilePicture(_image!);

        // อัปเดต URL ของรูปภาพใน Firestore
        await _profileController.updateUserData({'profile_pic': downloadUrl});

        // อัปเดต UI ด้วย URL ใหม่
        setState(() {
          profilePicUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปโหลดรูปโปรไฟล์สำเร็จ')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ')),
      );
    }
  }

  Future<void> _updateUserData() async {
    try {
      Map<String, dynamic> data = {
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
        'phone_number': phoneNumber ?? '',
        'profile_pic': profilePicUrl ?? '',
      };

      await _profileController.updateUserData(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปเดตข้อมูลสำเร็จ')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปเดตข้อมูล')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StaffMainLayout(
      selectedIndex: 4,
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
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          color: const Color(0xFF3B83F6),
                          height: 100,
                        ),
                        Positioned(
                          top: 50,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: _pickImage,
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
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField('ชื่อ', firstName,
                                    (value) => firstName = value),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField('นามสกุล', lastName,
                                    (value) => lastName = value),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField('เบอร์โทรศัพท์', phoneNumber,
                              (value) => phoneNumber = value),
                          _buildTextField('Email', email, null, enabled: false),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _updateUserData,
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
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(
      String label, String? initialValue, Function(String)? onChanged,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        initialValue: initialValue,
        enabled: enabled,
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
      ),
    );
  }
}
