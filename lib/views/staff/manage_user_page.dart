import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medibridge_application/views/staff/add_edit_user_page.dart';
import 'package:medibridge_application/widgets/staff_main_layout.dart';
import './../../services/auth_service.dart';
import './../../models/user_model.dart';

class ManageUserPage extends StatefulWidget {
  const ManageUserPage({Key? key}) : super(key: key);

  @override
  State<ManageUserPage> createState() => _ManageUserPageState();
}

class _ManageUserPageState extends State<ManageUserPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String? selectedRole;
  List<UserModel> users = [];
  bool isLoading = false;

  void _searchUsersByNameAndRole() async {
    setState(() {
      isLoading = true;
    });
    try {
      String nameQuery = _searchController.text.trim();
      List<UserModel> results = await _authService.searchUsersByNameAndRole(
        nameQuery: nameQuery.isNotEmpty ? nameQuery : null,
        roleQuery: selectedRole, 
      );
      setState(() {
        users = results;
      });
    } catch (e) {
      print('Error during search: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StaffMainLayout(
        selectedIndex: 0,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'จัดการผู้ใช้งาน',
              style: GoogleFonts.prompt(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ปุ่มเพิ่มผู้ใช้งานใหม่
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        // เปิดหน้า AddEditUserPage และรอรับค่าผลลัพธ์ที่ส่งกลับมา
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AddEditUserPage(user: null),
                          ),
                        );

                        // ถ้า result เป็น true แสดงว่ามีการอัปเดตข้อมูล ให้รีเฟรชรายการผู้ใช้งาน
                        if (result == true) {
                          _searchUsersByNameAndRole();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 5,
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20),
                      ),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text(
                        'เพิ่มผู้ใช้งานใหม่',
                        style: GoogleFonts.prompt(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'ค้นหาจาก "รายชื่อ"',
                    style: GoogleFonts.prompt(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ช่องค้นหารายชื่อ
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ค้นหารายชื่อ',
                    hintStyle:
                        GoogleFonts.prompt(fontSize: 16, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF3B83F6),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'ค้นหาจาก "บทบาท"',
                    style: GoogleFonts.prompt(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ช่องเลือกบทบาท
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value;
                    });
                  },
                  items: const [
                    DropdownMenuItem(value: 'Doctor', child: Text('Doctor')),
                    DropdownMenuItem(value: 'Staff', child: Text('Staff')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'กรุณาเลือกบทบาท',
                    labelStyle: GoogleFonts.prompt(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _searchUsersByNameAndRole,
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    backgroundColor: const Color(0xFF3B83F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: Text(
                    'ค้นหา',
                    style: GoogleFonts.prompt(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // แสดงผลผู้ใช้งาน
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (users.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(70.0),
                      child: Text(
                        'ไม่พบผู้ใช้งาน',
                        style: GoogleFonts.prompt(
                          fontSize: 16,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                  ),

                if (users.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        title: Text('${user.firstName} ${user.lastName}'),
                        subtitle: Text(user.role),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddEditUserPage(user: user),
                              ),
                            );
                            if (result == true) {
                              _searchUsersByNameAndRole();
                            }
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ));
  }
}
