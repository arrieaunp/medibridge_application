import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArticlePage extends StatelessWidget {
  final String title;
  final String content;
  final String imagePath;

  const ArticlePage({super.key, required this.title, required this.content, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.prompt()),
        backgroundColor: const Color(0xFF3B83F6),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(imagePath, fit: BoxFit.cover),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.prompt(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(content, style: GoogleFonts.prompt(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
