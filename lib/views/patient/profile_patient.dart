import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import './../../utils/signout.dart';
import './../../controllers/patient_profile_controller.dart';
import './../../widgets/main_layout.dart';

class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({Key? key}) : super(key: key);

  @override
  _PatientProfilePageState createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final ProfileController _profileController = ProfileController();

  String? firstName;
  String? lastName;
  String? phoneNumber;
  String? email;
  String? profilePicUrl;
  String? gender;
  String? bloodType;
  String? allergies;
  String? chronicConditions;
  String? dateOfBirth;
  String? emergencyContact;
  int? height;
  int? weight;

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

    final userData = await _profileController.loadUserData();
    if (userData != null) {
      setState(() {
        firstName = userData['user']['first_name'];
        lastName = userData['user']['last_name'];
        phoneNumber = userData['user']['phone_number'];
        email = userData['user']['email'];
        profilePicUrl = userData['user']['profile_pic'];
        allergies = userData['patient']['allergies'];
        chronicConditions = userData['patient']['chronic_conditions'];
        dateOfBirth = userData['patient']['date_of_birth'];
        emergencyContact = userData['patient']['emergency_contact'];
        gender = userData['patient']['gender']?.isNotEmpty == true
            ? userData['patient']['gender']
            : 'ชาย';
        bloodType = userData['patient']['blood_type']?.isNotEmpty == true
            ? userData['patient']['blood_type']
            : 'A';

        height = userData['patient']['height'];
        weight = userData['patient']['weight'];
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        await _profileController.uploadImage(_image!);

        // อัปเดต UI หลังจากอัปโหลดรูปสำเร็จ
        _loadUserData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('คุณไม่ได้เลือกรูปภาพ')),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกภาพ')),
      );
    }
  }

  Future<void> _updateUserData() async {
    try {
      Map<String, dynamic> data = {
        'user': {
          'first_name': firstName ?? '',
          'last_name': lastName ?? '',
          'phone_number': phoneNumber ?? '',
          'profile_pic': profilePicUrl ?? '',
        },
        'patient': {
          'allergies': allergies ?? '',
          'blood_type': bloodType,
          'chronic_conditions': chronicConditions ?? '',
          'date_of_birth': dateOfBirth,
          'emergency_contact': emergencyContact ?? '',
          'gender': gender,
          'height': height,
          'weight': weight,
        },
      };

      await _profileController.updateUserData(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปเดตข้อมูลสำเร็จ')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปเดตข้อมูลไม่สำเร็จ')),
      );
    }
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        dateOfBirth = DateFormat('dd MMMM yyyy').format(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Profile',
            style: GoogleFonts.prompt(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF3B83F6),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () {
                showLogoutConfirmationDialog(context);
              },
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
                              onTap: () async {
                                bool canEditProfilePic =
                                    await _profileController
                                        .canEditProfilePicture();
                                if (canEditProfilePic) {
                                  _pickImage();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'ไม่สามารถแก้ไขรูปโปรไฟล์ได้เมื่อเข้าสู่ระบบผ่าน Google'),
                                    ),
                                  );
                                }
                              },
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
                      height: 30,
                    ),
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
                          _buildTextField(
                              'เบอร์ติดต่อฉุกเฉิน',
                              emergencyContact,
                              (value) => emergencyContact = value),
                          const SizedBox(height: 16),
                          TextFormField(
                            readOnly: true,
                            controller:
                                TextEditingController(text: dateOfBirth),
                            decoration: InputDecoration(
                              labelText: 'วัน/เดือน/ปี เกิด',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 12.0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            onTap: _selectDate,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: gender,
                                  decoration: InputDecoration(
                                    labelText: 'เพศ',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                                  ),
                                  items: ['ชาย', 'หญิง', 'อื่นๆ']
                                      .map((gender) => DropdownMenuItem(
                                            value: gender,
                                            child: Text(gender),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      gender = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: bloodType,
                                  decoration:  InputDecoration(
                                    labelText: 'กรุ๊ปเลือด',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                                  ),
                                  items: ['A', 'B', 'AB', 'O']
                                      .map((bloodType) => DropdownMenuItem(
                                            value: bloodType,
                                            child: Text(bloodType),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      bloodType = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                    'น้ำหนัก (kg)',
                                    weight?.toString(),
                                    (value) => weight = int.tryParse(value)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                    'ส่วนสูง (cm)',
                                    height?.toString(),
                                    (value) => height = int.tryParse(value)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField('ประวัติการแพ้', allergies,
                              (value) => allergies = value),
                          _buildTextField('โรคประจำตัว', chronicConditions,
                              (value) => chronicConditions = value),
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
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 8.0),
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
