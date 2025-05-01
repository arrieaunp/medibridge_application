import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './../../controllers/auth_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Controllers สำหรับเก็บข้อมูลที่ผู้ใช้กรอกในแต่ละฟิลด์
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // เพิ่ม GlobalKey<FormState> สำหรับจัดการ validate
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // 1) ใช้ MediaQuery เพื่อคำนวณขนาดหน้าจอ
    final screenWidth = MediaQuery.of(context).size.width;

    // 2) หากจอเล็ก (< 400) ลด padding แนวนอนของปุ่มลง
    final double horizontalButtonPadding = screenWidth < 400 ? 40 : 80;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ลงทะเบียน',
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextFormField('ชื่อ', _firstNameController),
              const SizedBox(height: 20),
              _buildTextFormField('นามสกุล', _lastNameController),
              const SizedBox(height: 20),
              _buildTextFormField('เบอร์โทรศัพท์', _phoneNumberController),
              const SizedBox(height: 20),
              _buildTextFormField('Email', _emailController, isEmail: true),
              const SizedBox(height: 20),
              _buildPasswordFormField(
                'รหัสผ่าน',
                _obscurePassword,
                (newValue) {
                  setState(() {
                    _obscurePassword = newValue;
                  });
                },
                _passwordController,
              ),
              const SizedBox(height: 20),
              _buildPasswordFormField(
                'ยืนยันรหัสผ่าน',
                _obscureConfirmPassword,
                (newValue) {
                  setState(() {
                    _obscureConfirmPassword = newValue;
                  });
                },
                _confirmPasswordController,
              ),
              const SizedBox(height: 40),

              // ปุ่ม "ลงทะเบียน"
              Center(
                // 3) ใช้ ConstrainedBox จำกัดความกว้างสูงสุด (maxWidth)
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  // 4) ทำปุ่มให้เต็มความกว้าง ด้วย SizedBox(width: double.infinity)
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                if (_passwordController.text ==
                                    _confirmPasswordController.text) {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  try {
                                    await AuthController().registerNewUser(
                                      firstName: _firstNameController.text,
                                      lastName: _lastNameController.text,
                                      phoneNumber: _phoneNumberController.text,
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                    );
                                    if (mounted) {
                                      Navigator.pushNamed(
                                          context, '/patientHome');
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  } finally {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('รหัสผ่านไม่ตรงกัน'),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        // 5) ใช้ horizontalButtonPadding แทน 135
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalButtonPadding,
                          vertical: 15,
                        ),
                        backgroundColor: const Color(0xFF3B83F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : Text(
                              'ลงทะเบียน',
                              style: GoogleFonts.prompt(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ปุ่ม "มีบัญชีอยู่แล้ว?"
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF3B83F6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalButtonPadding,
                          vertical: 15,
                        ),
                      ),
                      child: Text(
                        'มีบัญชีอยู่แล้ว?',
                        style: GoogleFonts.prompt(
                          fontSize: 16,
                          color: const Color(0xFF3B83F6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
    String label,
    TextEditingController controller, {
    bool isEmail = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.prompt(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'กรุณากรอก$label';
        }
        if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'รูปแบบอีเมลไม่ถูกต้อง';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordFormField(
    String label,
    bool obscureText,
    Function(bool) toggleVisibility,
    TextEditingController controller,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.prompt(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            toggleVisibility(!obscureText);
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'กรุณากรอก$label';
        }
        if (value.length < 6) {
          return 'รหัสผ่านควรมีอย่างน้อย 6 ตัวอักษร';
        }
        return null;
      },
    );
  }
}
