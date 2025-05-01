import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopRatedDoctorsCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> doctors;

  const TopRatedDoctorsCarousel({Key? key, required this.doctors}) : super(key: key);

  @override
  _TopRatedDoctorsCarouselState createState() => _TopRatedDoctorsCarouselState();
}

class _TopRatedDoctorsCarouselState extends State<TopRatedDoctorsCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Our Doctors',
                  style: GoogleFonts.prompt(
                      color: const Color(0xFF3B83F6),
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/doctorsList');
                },
                child: Text('See all', style: GoogleFonts.prompt(color: Colors.blue)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        CarouselSlider(
          options: CarouselOptions(
            height: 120, 
            viewportFraction: 1.0, 
            enableInfiniteScroll: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          items: widget.doctors.map((doctor) {
            return _buildDoctorCard(context, doctor);
          }).toList(),
        ),
        // Dot Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.doctors.length, (index) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == index ? Colors.blue : Colors.grey.withOpacity(0.4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDoctorCard(BuildContext context, Map<String, dynamic> doctor) {
    return GestureDetector(
      onTap: () {
        if (doctor.containsKey('id') && doctor['id'] != null) {
          Navigator.pushNamed(
            context,
            '/doctorDetail',
            arguments: {
              'doctor_id': doctor['id'], 
            },
          );
        } else {
          print('❌ Error: doctor_id is missing');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 25,
              backgroundImage: doctor['profile_pic'] != null && doctor['profile_pic'].isNotEmpty
                  ? NetworkImage(doctor['profile_pic'])
                  : const AssetImage('assets/images/doctor_placeholder.png') as ImageProvider,
            ),
            const SizedBox(width: 12),
            // Doctor Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor['name'] ?? 'Unknown Doctor',
                    style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    doctor['specialization'] ?? 'Specialization Unknown',
                    style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            // Status Indicator
            Icon(Icons.circle, color: Colors.blue), // เปลี่ยนสีตามสถานะ
          ],
        ),
      ),
    );
  }
}
