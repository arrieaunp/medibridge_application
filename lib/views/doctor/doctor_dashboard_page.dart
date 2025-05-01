import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medibridge_application/controllers/doctor_dashboard_controller.dart';
import 'package:shimmer/shimmer.dart';

class DoctorDashboardPage extends StatefulWidget {
  final String doctorId;

  const DoctorDashboardPage({super.key, required this.doctorId});

  @override
  _DoctorDashboardPageState createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  late DoctorDashboardController _controller;
  bool _isLoading = true;
  String _selectedFilter = "สัปดาห์";

  @override
  void initState() {
    super.initState();
    _controller = DoctorDashboardController(doctorId: widget.doctorId);
    _fetchData();
  }

  Future<void> _fetchData() async {
    await _controller.fetchDashboardData();
    setState(() {
      _isLoading = false;
    });
  }

  List<String> _getLabels() {
    switch (_selectedFilter) {
      case "สัปดาห์":
        return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      case "เดือน":
        return ["Week1", "Week2", "Week3", "Week4"];
      case "ปี":
        return [
          "Jan",
          "Feb",
          "Mar",
          "Apr",
          "May",
          "Jun",
          "Jul",
          "Aug",
          "Sep",
          "Oct",
          "Nov",
          "Dec"
        ];
      default:
        return [];
    }
  }

  List<double> _getData() {
    switch (_selectedFilter) {
      case "สัปดาห์":
        return _controller.weeklyData;
      case "เดือน":
        return _controller.monthlyData;
      case "ปี":
        return _controller.yearlyData;
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Dashboard แพทย์",
            style: GoogleFonts.prompt(fontWeight: FontWeight.bold,color: Colors.white)),
        elevation: 0,
        backgroundColor: const Color(0xFF3B83F6),
      ),
      body: _isLoading
          ? _buildShimmerLoading() // เพิ่ม Shimmer Effect ตอนโหลด
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 20),
                  _buildFilterDropdown(),
                  const SizedBox(height: 10),
                  _buildDynamicChart(),
                  const SizedBox(height: 20),
                  _buildFeedbackSection(),
                ],
              ),
            ),
    );
  }

  // 🔥 Gradient Summary Cards
  Widget _buildSummaryCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _summaryCard("รายได้รวม", "฿${_controller.totalEarnings}",
            Icons.monetization_on, Colors.blueAccent),
        _summaryCard(
            "คะแนนเฉลี่ย",
            "${_controller.averageRating.toStringAsFixed(1)} ⭐",
            Icons.star,
            const Color(0xFFFF9800)),
        _summaryCard("นัดหมาย", "${_controller.totalAppointments}",
            Icons.calendar_today, const Color(0xFF4CAF50)),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 36, color: Colors.white),
              const SizedBox(height: 8),
              Text(title,
                  style: GoogleFonts.prompt(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text(value,
                  style: GoogleFonts.prompt(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 Dropdown ฟิลเตอร์
  Widget _buildFilterDropdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("เลือกช่วงเวลา:",
            style:
                GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: _selectedFilter,
          onChanged: (String? newValue) {
            setState(() {
              _selectedFilter = newValue!;
            });
          },
          items: ["สัปดาห์", "เดือน", "ปี"]
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: GoogleFonts.prompt(fontSize: 16)),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 🔥 Animated Chart
  Widget _buildDynamicChart() {
    List<String> labels = _getLabels();
    List<double> data = _getData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("รายได้ ($_selectedFilter)",
            style:
                GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              barGroups: data.asMap().entries.map((entry) {
                int index = entry.key;
                double value = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: value,
                      width: 22,
                      color: const Color(0xFF3B83F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        "${value.toInt()}",
                        style: GoogleFonts.prompt(
                            fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Transform.rotate(
                        angle: -0.5,
                        child: Text(
                          labels[value.toInt()],
                          style: GoogleFonts.prompt(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  left: BorderSide(width: 1),
                  bottom: BorderSide(width: 1),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🔥 Feedback Section
  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("ความคิดเห็นจากผู้ป่วย",
            style:
                GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildFeedbackCarousel(),
      ],
    );
  }

// 🔥 ใช้ PageView + Dots Indicator
  Widget _buildFeedbackCarousel() {
    PageController _pageController = PageController();
    int feedbacksPerPage = 2; // ✅ แสดง 2 Feedbacks ต่อหน้า
    int totalPages = (_controller.feedbacks.length / feedbacksPerPage).ceil();

    return Column(
      children: [
        SizedBox(
          height: 245,
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalPages,
            itemBuilder: (context, pageIndex) {
              int start = pageIndex * feedbacksPerPage;
              int end = start + feedbacksPerPage;
              List<Map<String, dynamic>> currentFeedbacks =
                  _controller.feedbacks.sublist(
                      start,
                      end > _controller.feedbacks.length
                          ? _controller.feedbacks.length
                          : end);

              return SingleChildScrollView(
                  child: Column(
                children: currentFeedbacks.map((feedback) {
                  return Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        const BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          spreadRadius: 1,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading:
                          const Icon(Icons.comment, color: Colors.blueAccent),
                      title: Text(feedback['comment'],
                          style: GoogleFonts.prompt(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      subtitle: Text("คะแนน: ${feedback['rating']} ⭐",
                          style: GoogleFonts.prompt(
                              fontSize: 14, color: Colors.grey[700])),
                    ),
                  );
                }).toList(),
              ));
            },
          ),
        ),
        const SizedBox(height: 12),
        // 🔥 Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalPages, (index) {
            return AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                double selected =
                    (_pageController.page ?? 0) == index ? 1.0 : 0.5;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent.withOpacity(selected),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  // 🔥 Shimmer Effect
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.white,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          height: 80,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
