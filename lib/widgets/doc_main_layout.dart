import 'package:flutter/material.dart';
import 'doc_bottom_nav_bar.dart';

class DocMainLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
final String doctorId;

  const DocMainLayout({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.doctorId, 
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: DocBottomNavBar(
        selectedIndex: selectedIndex,
        onItemTapped: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/doctorHome',arguments: {'doctorId': doctorId},);
              break;
            case 1:
              Navigator.pushNamed(context, '/doctorSchedule',arguments: {'doctorId': doctorId});
              break;
            case 2:
              Navigator.pushNamed(context, '/doctorNotifications',arguments: {'doctorId': doctorId});
              break;
            case 3:
              Navigator.pushReplacementNamed(
                context,
                '/doctorProfile',
                arguments: {'doctorId': doctorId}, 
              );
              break;
          }
        },
      ),
    );
  }
}
