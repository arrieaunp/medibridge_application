import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medibridge_application/services/feedback_service.dart';
import 'package:medibridge_application/services/medical_record_service.dart';

class FeedbackPage extends StatefulWidget {
  final String doctorId;
  final String appointmentId;

  const FeedbackPage({
    super.key,
    required this.doctorId,
    required this.appointmentId,
  });

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final FeedbackService _feedbackService = FeedbackService();
  final MedicalRecordService _medicalRecordService = MedicalRecordService();
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  Map<String, String>? doctorInfo;
  bool _hasExistingFeedback = false;

  @override
  void initState() {
    super.initState();
    _fetchDoctorInfo();
    _fetchExistingFeedback();
  }

  Future<void> _fetchDoctorInfo() async {
    var info = await _medicalRecordService.getDoctorInfo(widget.doctorId);
    setState(() {
      doctorInfo = info;
    });
  }

  Future<void> _fetchExistingFeedback() async {
    var feedback = await _feedbackService.getFeedback(
      doctorId: widget.doctorId,
      appointmentId: widget.appointmentId,
    );

    if (feedback != null) {
      setState(() {
        _rating = feedback['rating'];
        _commentController.text = feedback['comment'];
        _hasExistingFeedback = true;
      });
    }
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาให้คะแนนก่อนส่ง")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _feedbackService.submitOrUpdateFeedback(
        doctorId: widget.doctorId,
        appointmentId: widget.appointmentId,
        rating: _rating,
        comment: _commentController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ส่งความคิดเห็นเรียบร้อย!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Feedback",style: GoogleFonts.prompt(fontWeight: FontWeight.bold),),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (doctorInfo != null) _buildDoctorProfile(),
            const SizedBox(height: 16),

            _buildSectionTitle("กรุณาให้คะแนนการบริการของแพทย์"),
            const SizedBox(height: 8),
            _buildRatingStars(),
            const SizedBox(height: 16),

            _buildSectionTitle("แสดงความคิดเห็นเพิ่มเติม"),
            const SizedBox(height: 8),
            _buildCommentBox(),
            const SizedBox(height: 20),

            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  // 🔹 โปรไฟล์แพทย์ใน Card พร้อมดีไซน์สวยงาม
  Widget _buildDoctorProfile() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: doctorInfo!['profile_pic']!.isNotEmpty
                ? NetworkImage(doctorInfo!['profile_pic']!)
                : null,
            backgroundColor: Colors.grey[300],
            child: doctorInfo!['profile_pic']!.isEmpty
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              doctorInfo!['name'] ?? 'ไม่พบข้อมูลแพทย์',
              style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 หัวข้อเซคชั่น
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  // 🔹 Animation ดาวให้คะแนน
  Widget _buildRatingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = index + 1;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(6),
            child: Icon(
              index < _rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: index < _rating ? 42 : 38,
            ),
          ),
        );
      }),
    );
  }

  // 🔹 กล่องแสดงความคิดเห็นที่ดูหรูขึ้น
  Widget _buildCommentBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: TextField(
        controller: _commentController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: "เขียนความคิดเห็นของคุณ...",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  // 🔹 ปุ่มส่งความคิดเห็นแบบ Gradient และ Animation
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: _isSubmitting ? null : _submitFeedback,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Center(
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _hasExistingFeedback ? "อัปเดตความคิดเห็น" : "ส่งความคิดเห็น",
                    style: GoogleFonts.prompt(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}
