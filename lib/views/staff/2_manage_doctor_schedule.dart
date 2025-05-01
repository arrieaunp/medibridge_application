import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../controllers/doctor_schedule_controller.dart';

class ManageDoctorSchedulePage2 extends StatefulWidget {
  final String doctorName;
  final String doctorId;
  final DateTime? date;
  final String? scheduleId;

  ManageDoctorSchedulePage2({
    required this.doctorName,
    required this.doctorId,
    this.date,
    this.scheduleId,
  });

  @override
  _ManageDoctorSchedulePage2State createState() =>
      _ManageDoctorSchedulePage2State();
}

class _ManageDoctorSchedulePage2State extends State<ManageDoctorSchedulePage2> {
  final DoctorScheduleController _controller = DoctorScheduleController();

  /// เก็บวันที่ที่ผู้ใช้เลือกปัจจุบัน
  DateTime? _currentDate;

  final TextEditingController _dateController = TextEditingController();
  String? _selectedStartTime;
  String? _selectedEndTime;

  final List<String> _timeOptions = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
  ];

  @override
  void initState() {
    super.initState();

    // ถ้ามีวันที่ส่งมาจากหน้าที่แล้ว ให้ใช้เป็นค่าเริ่มต้น
    _currentDate = widget.date;

    // อัปเดต TextField แสดงวันที่ ถ้ามี
    if (_currentDate != null) {
      _dateController.text = DateFormat('dd/MM/yyyy').format(_currentDate!);
    }

    // ถ้ามี scheduleId แปลว่าเป็นการแก้ไขตารางเวรเดิม → โหลดข้อมูลเวลาเริ่ม-สิ้นสุด
    if (widget.scheduleId != null) {
      _loadSchedule();
    } else {
      // ถ้าไม่มี scheduleId อาจตั้งค่าเริ่มต้นของเวลาว่างเปล่าก่อน
      _selectedStartTime = null;
      _selectedEndTime = null;
    }
  }

  /// ฟังก์ชันให้ผู้ใช้เลือกวันที่ใหม่ผ่าน DatePicker
  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _currentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _currentDate = pickedDate;
        _dateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
      // หากต้องการโหลดตารางเวรของวันที่ใหม่เลย ก็สามารถเรียก _loadSchedule() ได้ที่นี่
      // แต่ต้องระวังว่าการโหลดมาแล้วจะ override ค่า start/endTime ที่ตั้งไว้หรือไม่
    }
  }

  /// โหลดข้อมูลตารางเวรจาก Firestore ตาม doctorId + date
  Future<void> _loadSchedule() async {
    if (widget.doctorId.isEmpty) {
      print("Error: doctorId is empty");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบ doctorId กรุณาลองใหม่อีกครั้ง')),
      );
      return;
    }
    if (_currentDate == null) {
      print("Error: date is null, can't load schedule");
      return;
    }

    try {
      print(
          "Loading schedule for doctorId: ${widget.doctorId} on date: $_currentDate");

      final schedule =
          await _controller.getScheduleForDate(widget.doctorId, _currentDate!);

      setState(() {
        _selectedStartTime =
            schedule['start_time'] ?? schedule['default_start_time'];
        _selectedEndTime = schedule['end_time'] ?? schedule['default_end_time'];
      });

      print("Set schedule: Start: $_selectedStartTime, End: $_selectedEndTime");
    } catch (e) {
      print("Error loading schedule: $e");
    }
  }

  /// บันทึกตารางเวร (saveCustomSchedule) ลง Firestore
  Future<void> _saveSchedule() async {
    if (_currentDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกวันที่')),
      );
      return;
    }

    if (_selectedStartTime == null || _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    final DateFormat timeFormat = DateFormat("HH:mm");
    final DateTime startTimeParsed = timeFormat.parse(_selectedStartTime!);
    final DateTime endTimeParsed = timeFormat.parse(_selectedEndTime!);

    // ตรวจสอบว่าเวลาเริ่มต้นต้องน้อยกว่าเวลาสิ้นสุด
    if (startTimeParsed.compareTo(endTimeParsed) >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เวลาสิ้นสุดต้องมากกว่าเวลาเริ่มต้น')),
      );
      return;
    }

    try {
      await _controller.saveCustomSchedule(
        doctorId: widget.doctorId,
        date: _currentDate!,
        startTime: _selectedStartTime!,
        endTime: _selectedEndTime!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ บันทึกข้อมูลสำเร็จและแจ้งเตือนแพทย์เรียบร้อย')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'เพิ่ม/แก้ไขตารางเวรแพทย์',
          style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ชื่อแพทย์
            Text(
              'แพทย์: ${widget.doctorName}',
              style:
                  GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ช่องแสดงวันที่
            TextField(
              controller: _dateController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'วันที่',
                labelStyle: GoogleFonts.prompt(),
                suffixIcon: Icon(Icons.calendar_today), // ไอคอนปฏิทิน
              ),
              readOnly: true,
              onTap: _pickDate, // เมื่อกดช่องวันที่ → เปิด DatePicker
            ),
            const SizedBox(height: 16),

            // เวลาเริ่ม
            DropdownButtonFormField<String>(
              value: _timeOptions.contains(_selectedStartTime) &&
                      _selectedStartTime != ''
                  ? _selectedStartTime
                  : null,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'เวลาเริ่ม',
                labelStyle: GoogleFonts.prompt(),
              ),
              items: _timeOptions.map((time) {
                return DropdownMenuItem(
                  value: time,
                  child: Text(time),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStartTime = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // เวลาสิ้นสุด
            DropdownButtonFormField<String>(
              value: _timeOptions.contains(_selectedEndTime) &&
                      _selectedEndTime != ''
                  ? _selectedEndTime
                  : null,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'เวลาสิ้นสุด',
                labelStyle: GoogleFonts.prompt(),
              ),
              items: _timeOptions.map((time) {
                return DropdownMenuItem(
                  value: time,
                  child: Text(time),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedEndTime = value;
                });
              },
            ),
            const SizedBox(height: 32),

            // ปุ่ม ยกเลิก และ บันทึก
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text(
                    'ยกเลิก',
                    style: GoogleFonts.prompt(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveSchedule,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text(
                    'บันทึก',
                    style: GoogleFonts.prompt(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
