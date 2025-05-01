import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medibridge_application/views/staff/2_manage_doctor_schedule.dart';
import 'package:medibridge_application/widgets/staff_main_layout.dart';
import './../../controllers/doctor_schedule_controller.dart';

class ManageDoctorSchedulePage extends StatefulWidget {
  @override
  _ManageDoctorSchedulePageState createState() =>
      _ManageDoctorSchedulePageState();
}

class _ManageDoctorSchedulePageState extends State<ManageDoctorSchedulePage> {
  final DoctorScheduleController _controller = DoctorScheduleController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _doctorNameController = TextEditingController();
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _schedules = [];

  /// ตัวแปรบ่งชี้สถานะ loading
  bool _isLoading = false;

  // ค้นหาด้วยวันที่
  void _searchByDate() async {
    if (_selectedDate == null) {
      print('No date selected'); // Debug log
      return;
    }
    
    // Set loading true ก่อนเริ่มค้นหา
    setState(() {
      _isLoading = true;
    });

    String dayOfWeek = DateFormat.EEEE('th_TH').format(_selectedDate!);
    print('Selected Day: $dayOfWeek'); // Debug log

    try {
      final results = await _controller.getSchedulesForDateWithUserName(
          _selectedDate!, dayOfWeek);

      if (results.isEmpty) {
        print('No schedules found'); // Debug log
        setState(() {
          _schedules = [];
        });
      } else {
        print('Schedules Found: ${results.length}'); // Debug log
        print('Schedules Data: $results'); // Debug ข้อมูลที่ได้จาก Controller
        setState(() {
          _schedules = results;
        });
      }
    } catch (e) {
      print('Error fetching schedules: $e');
      setState(() {
        _schedules = [];
      });
    } finally {
      // Set loading false หลังจบการค้นหา
      setState(() {
        _isLoading = false;
      });
    }
  }

  // เลือกวันที่
  void _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });

      String formattedDate =
          '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';

      _dateController.text = formattedDate;

      _searchByDate();
    }
  }

  // ค้นหาด้วยชื่อ
  void _searchByName() async {
    String partialName = _doctorNameController.text.trim();
    if (partialName.isEmpty) {
      debugPrint('Please enter a name');
      return;
    }

    // กรณีผู้ใช้ยังไม่เลือกวันที่ จะให้เป็นวันนี้ หรือแจ้งเตือนก็ได้
    DateTime dateToUse = _selectedDate ?? DateTime.now();

    // Set loading true ก่อนเริ่มค้นหา
    setState(() {
      _isLoading = true;
    });

    debugPrint('Searching for: $partialName');
    try {
      // เรียกฟังก์ชันโดยส่ง 2 arguments
      final results = await _controller.getSchedulesByPartialName(
        partialName, // String name
        dateToUse, // DateTime selectedDate
      );
      debugPrint('Schedules Found: ${results.length}');
      setState(() {
        _schedules = results;
      });
    } catch (e) {
      debugPrint('Error in _searchByName: $e');
    } finally {
      // Set loading false เมื่อค้นหาเสร็จ
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StaffMainLayout(
      selectedIndex: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'จัดการตารางแพทย์',
            style: GoogleFonts.prompt(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // ส่วนค้นหา
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // รูปภาพชิดซ้าย
                  Container(
                    width: 150, // ขนาดของรูป
                    height: 150,
                    child: Image.asset(
                      'assets/images/save-to-bookmarks.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16), // ระยะห่างระหว่างรูปภาพกับฟิลด์

                  // ฟิลด์ค้นหา
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end, // จัดชิดขวา
                      children: [
                        // ค้นหารายชื่อแพทย์
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _doctorNameController,
                                  decoration: InputDecoration(
                                    hintText: 'ค้นหาชื่อแพทย์',
                                    hintStyle: GoogleFonts.prompt(),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(8.0),
                                  ),
                                  onSubmitted: (_) => _searchByName(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.search, color: Colors.grey),
                                onPressed: _searchByName,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16), // ระยะห่างระหว่างฟิลด์

                        // ค้นหาด้วยวันที่
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _dateController,
                                  decoration: InputDecoration(
                                    hintText: 'ค้นหาวันที่',
                                    hintStyle: GoogleFonts.prompt(),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(8.0),
                                  ),
                                  readOnly: true,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.calendar_today, color: Colors.grey),
                                onPressed: () => _selectDate(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // ระยะห่างระหว่างส่วนค้นหากับรายการ

              // แสดง Loading Spinner ถ้ากำลังโหลดข้อมูล
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                // แสดงรายชื่อแพทย์ที่ค้นหา
                Expanded(
                  child: _schedules.isNotEmpty
                      ? ListView.builder(
                          itemCount: _schedules.length,
                          itemBuilder: (context, index) {
                            final schedule = _schedules[index];

                            final doctorName =
                                schedule['doctorName'] ?? 'ไม่ระบุชื่อ';
                            final start = schedule['start_time'] ?? 'ไม่ระบุ';
                            final end = schedule['end_time'] ?? 'ไม่ระบุ';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 4.0,
                              child: ListTile(
                                leading: const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.blue,
                                ),
                                title: Text(
                                  doctorName,
                                  style: GoogleFonts.prompt(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'เวลา: $start - $end\nความเชี่ยวชาญ: ${schedule['specialization'] ?? 'ไม่ระบุ'}',
                                  style: GoogleFonts.prompt(),
                                ),
                                trailing: const Icon(
                                  Icons.edit_outlined,
                                  size: 30,
                                  color: Colors.blueAccent,
                                ),
                                onTap: () {
                                  final doctorId = schedule['doctorId'] ?? '';
                                  print("Navigating to ManageDoctorSchedulePage2 with doctorId: $doctorId");

                                  if (doctorId.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('ไม่พบข้อมูล doctorId')),
                                    );
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ManageDoctorSchedulePage2(
                                        doctorName: schedule['doctorName'] ?? 'ไม่ระบุชื่อ',
                                        doctorId: doctorId,
                                        date: _selectedDate,
                                        scheduleId: schedule['scheduleId'] ?? '',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            'ไม่พบข้อมูลตารางเวร',
                            style: GoogleFonts.prompt(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
