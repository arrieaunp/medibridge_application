import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medibridge_application/services/doctor_schedule_service.dart';
import 'package:medibridge_application/views/doctor/change_schedule.dart';
import 'package:medibridge_application/widgets/doc_main_layout.dart';

class DoctorSchedulePage extends StatefulWidget {
  final String doctorId;

  const DoctorSchedulePage({Key? key, required this.doctorId})
      : super(key: key);

  @override
  _DoctorSchedulePageState createState() => _DoctorSchedulePageState();
}

class _DoctorSchedulePageState extends State<DoctorSchedulePage> {
  late Future<List<Map<String, dynamic>>> _schedulesFuture;
  String _selectedWeek = "สัปดาห์นี้"; // ตัวเลือกเริ่มต้น
  late String thisWeekRange;
  late String nextWeekRange;

  @override
  void initState() {
    super.initState();
    _calculateWeekRanges(); // คำนวณช่วงสัปดาห์
    _schedulesFuture = DoctorScheduleService().fetchSchedules(
      widget.doctorId,
      _getStartOfSelectedWeek(),
      _getEndOfSelectedWeek(),
    );
  }

  DateTime _getStartOfSelectedWeek() {
    final now = DateTime.now();
    return _selectedWeek == "สัปดาห์นี้"
        ? now.subtract(Duration(days: now.weekday - 1))
        : now
            .subtract(Duration(days: now.weekday - 1))
            .add(const Duration(days: 7));
  }

  DateTime _getEndOfSelectedWeek() {
    final startOfWeek = _getStartOfSelectedWeek();
    return startOfWeek.add(const Duration(days: 6));
  }

  void _calculateWeekRanges() {
    final now = DateTime.now();
    final startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfThisWeek = startOfThisWeek.add(const Duration(days: 6));
    final startOfNextWeek = startOfThisWeek.add(const Duration(days: 7));
    final endOfNextWeek = startOfNextWeek.add(const Duration(days: 6));

    final dateFormat = DateFormat('d/M/yyyy');
    thisWeekRange =
        '${dateFormat.format(startOfThisWeek)} - ${dateFormat.format(endOfThisWeek)}';
    nextWeekRange =
        '${dateFormat.format(startOfNextWeek)} - ${dateFormat.format(endOfNextWeek)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'ตารางเวร',
            style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
          ),
        ),
        body: DocMainLayout(
          selectedIndex: 1,
          doctorId: widget.doctorId,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedWeek,
                  decoration: InputDecoration(
                    labelText: 'เลือกสัปดาห์',
                    labelStyle: GoogleFonts.prompt(
                        fontSize: 16, fontWeight: FontWeight.w500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(color: Colors.grey, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(color: Colors.blue, width: 2.0),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  icon: Icon(Icons.calendar_today, color: Colors.blueAccent),
                  dropdownColor: Colors.white, // สีพื้นหลังของ dropdown
                  style: GoogleFonts.prompt(fontSize: 16, color: Colors.black),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedWeek = value;
                        _schedulesFuture =
                            DoctorScheduleService().fetchSchedules(
                          widget.doctorId,
                          _getStartOfSelectedWeek(),
                          _getEndOfSelectedWeek(),
                        );
                      });
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: "สัปดาห์นี้",
                      child: Text(
                        "สัปดาห์นี้ ($thisWeekRange)",
                        style: GoogleFonts.prompt(fontSize: 16),
                      ),
                    ),
                    DropdownMenuItem(
                      value: "สัปดาห์หน้า",
                      child: Text(
                        "สัปดาห์หน้า ($nextWeekRange)",
                        style: GoogleFonts.prompt(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _schedulesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(
                          child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
                    } else if (snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('ไม่มีข้อมูลในช่วงที่เลือก'));
                    }

                    final filteredSchedules = snapshot.data!;

                    return ListView.builder(
                      itemCount: filteredSchedules.length,
                      itemBuilder: (context, index) {
                        final schedule = filteredSchedules[index];
                        final isHighlighted =
                            index % 2 == 0; // สลับสีการ์ด (true สำหรับการ์ดคู่)

                        // Format the date into separate parts
                        final day =
                            DateFormat('d').format(schedule['date']); // วันที่
                        final month = DoctorScheduleService.formatThaiDate(
                                schedule['date'])
                            .split(' ')[1]; // เดือน
                        final year = DoctorScheduleService.formatThaiDate(
                                schedule['date'])
                            .split(' ')[2]; // ปี

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: isHighlighted
                                ? const Color(0xFF3B83F6)
                                : Colors.white, // กำหนดสีการ์ด
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // มุมบนซ้าย: วันที่
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          day, // Display day
                                          style: GoogleFonts.prompt(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: isHighlighted
                                                ? Colors.white
                                                : const Color(0xFF3B83F6),
                                          ),
                                        ),
                                        Text(
                                          month, // Display month
                                          style: GoogleFonts.prompt(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: isHighlighted
                                                ? Colors.white
                                                : const Color(0xFF3B83F6),
                                          ),
                                        ),
                                        Text(
                                          year, // Display year
                                          style: GoogleFonts.prompt(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            color: isHighlighted
                                                ? Colors.white
                                                : const Color(0xFF3B83F6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // มุมบนขวา: เวลา
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${schedule['start_time']} - ${schedule['end_time']}',
                                        style: GoogleFonts.prompt(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: isHighlighted
                                              ? Colors.white
                                              : const Color(0xFF3B83F6),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // มุมล่างขวา: ปุ่ม
                                      ElevatedButton(
                                        onPressed: () {
                                          // Example: Passing the schedule data to the ChangeSchedulePage
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ChangeSchedulePage(
                                                doctorId: widget.doctorId,
                                                selectedSchedule: {
                                                  'date': schedule[
                                                      'date'], // Pass the selected date
                                                  'time':
                                                      '${schedule['start_time']} - ${schedule['end_time']}', // Pass the selected time
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isHighlighted
                                              ? Colors.white
                                              : Colors.blue,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                        ),
                                        child: Text(
                                          "ขอเปลี่ยนตารางเวร",
                                          style: GoogleFonts.prompt(
                                            color: isHighlighted
                                                ? const Color(0xFF3B83F6)
                                                : Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ));
  }
}
