import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    // 1) คำนวณขนาดหน้าจอ
    final screenWidth = MediaQuery.of(context).size.width;
    // 2) หากจอ < 400 px ให้ลด padding แนวนอนในปุ่ม เหลือ 40;
    //    ถ้าใหญ่กว่านั้นใช้ 80 หรือปรับตามต้องการ
    final double horizontalButtonPadding = screenWidth < 400 ? 40 : 80;

    // 3) ไอคอน Google และ Facebook
    //    ถ้าหน้าจอเล็กก็ลดขนาดไอคอนลงได้
    final double googleIconSize = screenWidth < 400 ? 60 : 100;
    final double fbIconSize = screenWidth < 400 ? 25 : 35;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
        // ให้ Scroll ได้เมื่อจอเล็กหรือคีย์บอร์ดเด้งขึ้น
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'เข้าสู่ระบบ',
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'กรุณากรอกอีเมลและรหัสผ่าน',
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: const Color.fromARGB(255, 59, 131, 246),
                ),
              ),
              const SizedBox(height: 50),

              // 4) TextField อีเมล
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: GoogleFonts.prompt(),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 59, 131, 246),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 35),

              // 5) TextField พาสเวิร์ด + ลืมรหัสผ่าน
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: GoogleFonts.prompt(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 59, 131, 246),
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
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/forgot-password');
                      },
                      child: Text(
                        'ลืมรหัสผ่าน?',
                        style: GoogleFonts.prompt(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 85),

              // 6) ปุ่มเข้าสู่ระบบ - ขยายตามเนื้อที่ที่เหลือ (Responsive)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() {
                              _isLoading = true;
                            });
                            String email = _emailController.text.trim();
                            String password = _passwordController.text;
                            User? user =
                                await authService.signInWithEmailAndPassword(
                              email,
                              password,
                              context,
                            );
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'การเข้าสู่ระบบล้มเหลว กรุณาลองอีกครั้ง'),
                                ),
                              );
                            }
                            setState(() {
                              _isLoading = false;
                            });
                          },
        style: ElevatedButton.styleFrom(
          // ขยายเต็มความกว้าง + ตั้งค่า padding เหมือนกัน
          minimumSize: const Size.fromHeight(50),
          // หรือใช้ padding แบบเดียวกัน
          // padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
          backgroundColor: const Color(0xFF3B83F6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text(
                            'เข้าสู่ระบบ',
                            style: GoogleFonts.prompt(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 7) ปุ่มลงทะเบียนสมาชิกใหม่
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(color: Color(0xFF3B83F6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        // หรือ padding แบบเดียวกับ ElevatedButton
                        // padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
                      ),
                      child: Text(
                        'ลงทะเบียนสมาชิกใหม่',
                        style: GoogleFonts.prompt(
                          fontSize: 16,
                          color: const Color(0xFF3B83F6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 8) เส้นแบ่ง + ข้อความ "หรือเข้าสู่ระบบด้วย"
              Row(
                children: <Widget>[
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Colors.grey[400],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text(
                      'หรือเข้าสู่ระบบด้วย',
                      style: GoogleFonts.prompt(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 9) ปุ่มไอคอน Google/Facebook
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Image.asset('assets/images/gg.png'),
                    iconSize: googleIconSize,
                    onPressed: () async {
                      User? user = await authService.signInWithGoogle(context);
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('การเข้าสู่ระบบด้วย Google ล้มเหลว'),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 60),
                  IconButton(
                    icon: Image.asset('assets/images/fb.png'),
                    iconSize: fbIconSize,
                    onPressed: () async {
                      User? user =
                          await authService.signInWithFacebook(context);
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('การเข้าสู่ระบบด้วย Facebook ล้มเหลว'),
                          ),
                        );
                      }
                    },
                  )
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
