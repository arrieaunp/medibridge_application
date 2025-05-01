import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../controllers/appointment_controller.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({Key? key}) : super(key: key);

  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  final AppointmentController _controller = AppointmentController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'นัดหมายแพทย์',
            style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'วันที่',
                  style: GoogleFonts.prompt(
                      fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  'กรุณาเลือกวันที่ต้องการนัดหมาย',
                  style: GoogleFonts.prompt(fontSize: 16, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                TableCalendar(
                  focusedDay: _controller.focusedDay,
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2050),
                  selectedDayPredicate: (day) =>
                      _controller.selectedDate == day,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _controller.selectDate(selectedDay);
                      _controller.focusedDay = focusedDay;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'เวลา',
                  style: GoogleFonts.prompt(
                      fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  'กรุณาเลือกเวลาที่ต้องการนัดหมาย',
                  style: GoogleFonts.prompt(fontSize: 16, color: Colors.blue),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  value: _controller.selectedTime,
                  hint: Text('เลือกเวลา', style: GoogleFonts.prompt()),
                  items: _controller.getAvailableTimes().map((String time) {
                    return DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _controller.selectTime(value!);
                    });
                  },
                ),
                const SizedBox(height: 40),
                // Next Button
                Center(
                  child: // 1_appointment (AppointmentPage)
                      ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (_controller.canProceed()) {
                              Navigator.pushNamed(
                                context,
                                '/appointment2',
                                arguments: {
                                  'controller': _controller,
                                },
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('กรุณาเลือกวันที่และเวลาให้ครบถ้วน'),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 80, vertical: 16),
                      backgroundColor: const Color(0xFF3B83F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 3,
                    ),
                    child: Text(
                      'ถัดไป',
                      style: GoogleFonts.prompt(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
