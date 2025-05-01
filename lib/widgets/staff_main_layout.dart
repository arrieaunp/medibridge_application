import 'package:flutter/material.dart';
import 'staff_bottom_nav_bar.dart';

class StaffMainLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;

  const StaffMainLayout({
    super.key,
    required this.child,
    required this.selectedIndex, 
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: StaffBottomNavBar(
        selectedIndex: selectedIndex,
        onItemTapped: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/staffHome');
              break;
            case 1:
              Navigator.pushNamed(context, '/appointmentManagement');
              break;
            case 2:
              Navigator.pushNamed(context, '/doctorSchedules');
              break;
            case 3:
              Navigator.pushNamed(context, '/staffNotifications');
              break;
            case 4:
              Navigator.pushNamed(context, '/staffProfile');
              break;
          }
        },
      ),
    );
  }
}
