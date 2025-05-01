import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medibridge_application/services/doctor_schedule_service.dart';
import 'package:medibridge_application/widgets/doc_main_layout.dart';

class ChangeSchedulePage extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> selectedSchedule;

  const ChangeSchedulePage({
    Key? key,
    required this.doctorId,
    required this.selectedSchedule,
  }) : super(key: key);

  @override
  _ChangeSchedulePageState createState() => _ChangeSchedulePageState();
}

class _ChangeSchedulePageState extends State<ChangeSchedulePage> {
  final TextEditingController _reasonController = TextEditingController();
  final DoctorScheduleService _scheduleService = DoctorScheduleService();
  String? _selectedNewTimeSlot;

  final List<String> _timeSlots = [
    'เวรเช้า (08:00 - 12:00)',
    'เวรบ่าย (13:00 - 17:00)',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาใส่เหตุผลในการเปลี่ยนแปลง")),
      );
      return;
    }

    if (_selectedNewTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาเลือกช่วงเวลาที่ต้องการเปลี่ยน")),
      );
      return;
    }

    try {
      // ✅ เรียกใช้ API เพื่อส่งคำขอเปลี่ยนเวร
      await _scheduleService.requestScheduleChange(
        doctorId: widget.doctorId,
        schedule: {
          'date': widget.selectedSchedule['date'],
          'time': _selectedNewTimeSlot,
        },
        reason: reason,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ ส่งคำขอเปลี่ยนตารางเวรสำเร็จ")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ เกิดข้อผิดพลาด: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.selectedSchedule;

    final day = DateFormat('d').format(schedule['date']);
    final month =
        DoctorScheduleService.formatThaiDate(schedule['date']).split(' ')[1];
    final year =
        DoctorScheduleService.formatThaiDate(schedule['date']).split(' ')[2];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "เปลี่ยนตารางเวร",
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
      ),
      body: DocMainLayout(
        selectedIndex: 1,
        doctorId: widget.doctorId,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 5,
                  color: const Color(0xFF3B83F6),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              day,
                              style: GoogleFonts.prompt(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              month,
                              style: GoogleFonts.prompt(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              year,
                              style: GoogleFonts.prompt(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${schedule['time']} น.",
                              style: GoogleFonts.prompt(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'เลือกช่วงเวลาที่ต้องการเปลี่ยน',
                  style: GoogleFonts.prompt(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedNewTimeSlot,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _timeSlots.map((timeSlot) {
                    return DropdownMenuItem(
                      value: timeSlot,
                      child: Text(
                        timeSlot,
                        style: GoogleFonts.prompt(),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedNewTimeSlot = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // ✅ ช่องกรอกเหตุผล
                Text(
                  'ระบุเหตุผลในการเปลี่ยนแปลง',
                  style: GoogleFonts.prompt(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "กรุณาใส่เหตุผลในการเปลี่ยนแปลง...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: GoogleFonts.prompt(),
                ),

                const SizedBox(height: 24),

                // ✅ ปุ่ม ยืนยัน/ยกเลิก
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B83F6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          "ยืนยัน",
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          "ยกเลิก",
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
    );
  }
}
