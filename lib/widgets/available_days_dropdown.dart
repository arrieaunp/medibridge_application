import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AvailableDaysDropdown extends StatelessWidget {
  final List<String> selectedDays;
  final Function(List<String>) onDaysSelected;

  const AvailableDaysDropdown({
    Key? key,
    required this.selectedDays,
    required this.onDaysSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'กรุณาเลือกวันที่เข้าเวร',
          style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        DropdownSearch<String>.multiSelection(
          items: (f, cs) =>[
            'วันจันทร์',
            'วันอังคาร',
            'วันพุธ',
            'วันพฤหัสบดี',
            'วันศุกร์',
            'วันเสาร์',
            'วันอาทิตย์',
          ],
          selectedItems: selectedDays,
          onChanged: (List<String> selected) {
            onDaysSelected(selected); // คืนค่าที่เลือกกลับไปยัง Parent Widget
          },
          popupProps: const PopupPropsMultiSelection.menu(
            showSelectedItems: true, // แสดงรายการที่ถูกเลือก
          ),
        ),
      ],
    );
  }
}
