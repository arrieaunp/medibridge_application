import 'package:flutter/material.dart';

class StaffBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const StaffBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'หน้าหลัก',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_note),
          label: 'นัดหมาย',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'ตารางเวร',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'แจ้งเตือน',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'โปรไฟล์',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Color(0xFF3B83F6),
      unselectedItemColor: Colors.grey,
      onTap: onItemTapped,
      type: BottomNavigationBarType.fixed,
    );
  }
}
