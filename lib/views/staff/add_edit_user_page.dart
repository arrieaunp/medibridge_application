import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './../../services/auth_service.dart';
import './../../models/user_model.dart';

class AddEditUserPage extends StatefulWidget {
  final UserModel? user; // รับ UserModel หรือ null

  const AddEditUserPage({Key? key, this.user}) : super(key: key);

  @override
  State<AddEditUserPage> createState() => _AddEditUserPageState();
}

class _AddEditUserPageState extends State<AddEditUserPage> {
  final AuthService _authService = AuthService();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  String? _selectedRole;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();

    // ถ้ามีข้อมูลผู้ใช้งานให้เติมค่าลงในฟอร์ม
    if (widget.user != null) {
      _firstNameController.text = widget.user!.firstName;
      _lastNameController.text = widget.user!.lastName;
      _emailController.text = widget.user!.email;
      _phoneNumberController.text = widget.user!.phoneNumber;
      _selectedRole = widget.user!.role;
    }
  }

  Future<void> _saveUser() async {
    try {
      // ตรวจสอบ Role
      if (_selectedRole == null ||
          (_selectedRole != 'Doctor' && _selectedRole != 'Staff')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกบทบาท (Doctor หรือ Staff)')),
        );
        return;
      }

      // ตรวจสอบ Email
      if (_emailController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอกอีเมล')),
        );
        return;
      }

      // ถ้าเป็นการ "เพิ่ม" ผู้ใช้งานใหม่ (widget.user == null)
      // ต้องกรอกรหัสผ่านด้วย
      if (widget.user == null) {
        if (_passwordController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('กรุณากรอกรหัสผ่าน')),
          );
          return;
        }

        // ...โค้ดสร้าง UserModel และเรียก registerUser()...
        String? currentStaffEmail = _authService.staffEmail;
        String? currentStaffPassword = _authService.staffPassword;

        if (currentStaffEmail == null || currentStaffPassword == null) {
          print('❌ Error: Staff credentials are missing');
        }

        UserModel newUser = UserModel(
          userId: '',
          firstName: _firstNameController.text.trim(), // ไม่บังคับ
          lastName: _lastNameController.text.trim(), // ไม่บังคับ
          email: _emailController.text.trim(), // บังคับ
          phoneNumber: _phoneNumberController.text.trim(), // ไม่บังคับ
          role: _selectedRole!, // บังคับ
        );

        String password = _passwordController.text.trim();
        await _authService.registerUser(newUser, password);

        if (_selectedRole == 'Doctor') {
          await _authService.addDoctorToCollection(newUser.userId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ เพิ่มผู้ใช้งานใหม่สำเร็จ')),
          );
        }

        // ล็อกอินกลับเป็น Staff (ถ้าเก็บ credential ไว้)
        if (currentStaffEmail != null && currentStaffPassword != null) {
          print('🔄 Re-login as staff: $currentStaffEmail');
          await _authService.reLogin();
        }

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pop(context, true);
          });
        }
      } else {
        // ถ้าเป็นการ "แก้ไข" ผู้ใช้เดิม (widget.user != null)
        // ไม่บังคับกรอกรหัสผ่านใหม่
        await _authService.updateUser(
          widget.user!.userId,
          {
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone_number': _phoneNumberController.text.trim(),
            'role': _selectedRole!,
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ อัปเดตข้อมูลผู้ใช้งานสำเร็จ')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      print('❌ Error saving user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ เกิดข้อผิดพลาดในการบันทึกข้อมูล')),
        );
      }
    }
  }

  Future<void> _deleteUser() async {
    if (widget.user == null) return;

    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบผู้ใช้งานนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await _authService.deleteUser(widget.user!.userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ ลบผู้ใช้งานสำเร็จ')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        print('❌ Error deleting user: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ ลบผู้ใช้งานไม่สำเร็จ')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          widget.user == null ? 'เพิ่มผู้ใช้งาน' : 'แก้ไขข้อมูลผู้ใช้งาน',
          style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: widget.user != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteUser,
                  tooltip: 'ลบผู้ใช้งาน',
                ),
              ]
            : null,
      ),
      body: SafeArea(
        // <-- เพิ่ม SafeArea ตรงนี้
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height - // ลบ AppBar height
                        kToolbarHeight -
                        MediaQuery.of(context).padding.top,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('ชื่อ'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _firstNameController,
                    decoration: _inputDecoration('กรุณากรอก "ชื่อจริง"'),
                  ),
                  const SizedBox(height: 16),
                  buildSectionTitle('นามสกุล'),
                  TextField(
                    controller: _lastNameController,
                    decoration: _inputDecoration('กรุณากรอก "นามสกุล"'),
                  ),
                  const SizedBox(height: 16),
                  buildSectionTitle('บทบาท *'),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    hint: const Text(
                        'กรุณาเลือก "บทบาท"'), // <-- เพิ่ม hint เมื่อ _selectedRole เป็น null
                    items: const [
                      DropdownMenuItem(value: 'Doctor', child: Text('Doctor')),
                      DropdownMenuItem(value: 'Staff', child: Text('Staff')),
                    ],
                    onChanged: (value) => setState(() => _selectedRole = value),
                    decoration: _inputDecoration('กรุณาเลือก "บทบาท"'),
                  ),
                  const SizedBox(height: 16),
                  buildSectionTitle('อีเมล *'),
                  TextField(
                    controller: _emailController,
                    decoration: _inputDecoration('กรุณากรอก "อีเมล"'),
                  ),
                  const SizedBox(height: 16),
                  if (widget.user == null) ...[
                    buildSectionTitle('รหัสผ่าน *'),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'กรุณากรอก "รหัสผ่าน"',
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF707070),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF707070),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF3B83F6),
                            width: 2,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  buildSectionTitle('เบอร์โทรศัพท์'),
                  TextField(
                    controller: _phoneNumberController,
                    decoration: _inputDecoration('กรุณากรอก "เบอร์โทรศัพท์"'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _saveUser,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          backgroundColor: const Color(0xFF3B83F6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color.fromARGB(255, 255, 0, 0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                        ),
                        child: Text(
                          'ยกเลิก',
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            color: const Color.fromARGB(255, 255, 0, 0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String labelText) {
  return InputDecoration(
    labelText: labelText,
    labelStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Color(0xFF707070),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: Color(0xFF707070),
        width: 1.5,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: Color(0xFF3B83F6), // สีเส้นขอบเมื่อโฟกัส
        width: 2,
      ),
    ),
  );
}

Container buildSectionTitle(String text) {
  return Container(
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(
      text,
      style: GoogleFonts.prompt(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
