import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;

  const MainLayout({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavBar(
        selectedIndex: selectedIndex,
        onItemTapped: (index) async {
          final user = FirebaseAuth.instance.currentUser;
          final patientId = user?.uid;

          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/patientHome');
              break;
            case 1:
              if (patientId != null) {
                Navigator.pushNamed(
                  context,
                  '/statusAppointment',
                  arguments: {'patientId': patientId},
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User not logged in')),
                );
              }
              break;
            case 2:
              Navigator.pushNamed(
                context,
                '/paymentStatus',
                arguments: {'patientId': patientId},
              );
              break;
            case 3:
              Navigator.pushNamed(
                context,
                '/patientNotifications',
                arguments: {'patientId': patientId},
              );

            case 4:
              Navigator.pushNamed(context, '/patientProfile');
              break;
          }
        },
      ),
    );
  }
}
