import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medibridge_application/controllers/medical_record_controller.dart';
import 'package:medibridge_application/models/medical_record_model.dart';
import 'package:medibridge_application/models/prescription_model.dart';

class MedicalRecordDetailPage extends StatefulWidget {
  final String appointmentId;
  final String patientId;
  final String doctorId;
  const MedicalRecordDetailPage({
    Key? key,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required record,
  }) : super(key: key);

  @override
  _MedicalRecordDetailPageState createState() =>
      _MedicalRecordDetailPageState();
}

class _MedicalRecordDetailPageState extends State<MedicalRecordDetailPage> {
  final MedicalRecordController _controller = MedicalRecordController();

  late Future<Map<String, dynamic>> patientInfoFuture;
  late Future<MedicalRecordModel?> medicalRecordFuture;

  final TextEditingController diagnosisController = TextEditingController();
  final TextEditingController treatmentController = TextEditingController();
  List<PrescriptionModel> prescriptions = [];
  final Map<int, TextEditingController> nameControllers = {};
  final Map<int, TextEditingController> quantityControllers = {};
  final Map<int, TextEditingController> frequencyControllers = {};

  @override
  void initState() {
    super.initState();

    // (1) กำหนดค่าเริ่มต้นใน Controller
    diagnosisController.text = '';
    treatmentController.text = '';
    prescriptions = [];

    // (2) อย่าลืมกำหนดค่า patientInfoFuture
    patientInfoFuture = _controller.fetchPatientInfo(widget.patientId);

    // (3) กำหนดค่า medicalRecordFuture
    medicalRecordFuture = _controller.fetchMedicalRecord(widget.appointmentId);

    // (4) ถ้าอยากอัปเดตค่า diagnosis, treatment เมื่อดึง record มาได้
    medicalRecordFuture.then((record) {
      if (record != null && mounted) {
        setState(() {
          diagnosisController.text = record.diagnosis;
          treatmentController.text = record.treatment;
          prescriptions = List.from(record.prescriptions);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ประวัติการรักษา',
          style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: patientInfoFuture,
        builder: (context, patientSnapshot) {
          if (patientSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ตรวจสอบว่ามีข้อมูลผู้ป่วยหรือไม่
          Map<String, dynamic> patientData = patientSnapshot.data ??
              {
                'first_name': '',
                'last_name': '',
                'age': '',
                'gender': '',
                'allergies': '',
                'chronic_conditions': ''
              };

          return FutureBuilder<MedicalRecordModel?>(
            future: medicalRecordFuture,
            builder: (context, recordSnapshot) {
              if (recordSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: _buildPatientInfo(patientData),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMedicalRecordForm(diagnosisController,
                        treatmentController, prescriptions),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: TextField(
        controller: controller,
        maxLines: 3,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3B83F6), width: 2),
          ),
        ),
        style: GoogleFonts.prompt(),
      ),
    );
  }

  Widget _buildPatientInfo(Map<String, dynamic> patientData) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.prompt(
                    fontSize: 16, color: Colors.black, height: 2.5),
                children: [
                  const TextSpan(
                    text: 'ชื่อ: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text:
                        '${patientData['first_name'] ?? ''} ${patientData['last_name'] ?? ''}\n',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF3B83F6)),
                  ),
                  const TextSpan(
                      text: 'อายุ: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(
                    text: '${patientData['age']}\n',
                    style: const TextStyle(),
                  ),
                  const TextSpan(
                      text: 'เพศ: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(
                    text: '${patientData['gender']}\n',
                    style: const TextStyle(),
                  ),
                  const TextSpan(
                      text: 'ประวัติการแพ้ยา: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(
                    text: '${patientData['allergies']}\n',
                    style: const TextStyle(),
                  ),
                  const TextSpan(
                      text: 'โรคประจำตัว: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(
                    text: '${patientData['chronic_conditions']}\n',
                    style: const TextStyle(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionSection(List<PrescriptionModel> prescriptionsList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'การสั่งยา',
            style: GoogleFonts.prompt(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3B83F6)),
          ),
        ),
        if (prescriptionsList.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("ไม่มีข้อมูลการสั่งยา", style: GoogleFonts.prompt()),
          ),
        ...prescriptionsList.asMap().entries.map((entry) {
          int index = entry.key;
          PrescriptionModel prescription = entry.value;

          // ใช้ FocusNode เพื่อตรวจจับโฟกัสของ TextField
          FocusNode nameFocusNode = FocusNode();
          FocusNode quantityFocusNode = FocusNode();
          FocusNode frequencyFocusNode = FocusNode();

          nameControllers[index] ??=
              TextEditingController(text: prescription.name);
          quantityControllers[index] ??=
              TextEditingController(text: prescription.quantity);
          frequencyControllers[index] ??=
              TextEditingController(text: prescription.frequency);

          void setupFocusListener(FocusNode focusNode,
              TextEditingController controller, String defaultValue) {
            focusNode.addListener(() {
              if (focusNode.hasFocus && controller.text == defaultValue) {
                controller.clear(); // ลบค่าเริ่มต้นเมื่อกด
              } else if (!focusNode.hasFocus && controller.text.isEmpty) {
                controller.text =
                    defaultValue; // คืนค่าเริ่มต้นถ้าไม่ได้กรอกอะไร
              }
            });
          }

          // ตั้งค่า FocusNode ให้กับ TextField
          setupFocusListener(
              nameFocusNode, nameControllers[index]!, 'ชื่อยาใหม่');
          setupFocusListener(
              quantityFocusNode, quantityControllers[index]!, 'ขนาดยา');
          setupFocusListener(
              frequencyFocusNode, frequencyControllers[index]!, 'วิธีใช้ยา');

          return Card(
            color: const Color.fromARGB(255, 255, 255, 255),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameControllers[index],
                    focusNode: nameFocusNode,
                    decoration: InputDecoration(
                        labelText: 'ชื่อยา', labelStyle: GoogleFonts.prompt()),
                    onChanged: (value) {
                      prescriptionsList[index] = PrescriptionModel(
                        name: value,
                        quantity: prescriptionsList[index].quantity,
                        frequency: prescriptionsList[index].frequency,
                      );
                    },
                  ),
                  TextField(
                    controller: quantityControllers[index],
                    focusNode: quantityFocusNode,
                    decoration: InputDecoration(
                        labelText: 'ปริมาณ', labelStyle: GoogleFonts.prompt()),
                    onChanged: (value) {
                      prescriptionsList[index] = PrescriptionModel(
                        name: prescriptionsList[index].name,
                        quantity: value,
                        frequency: prescriptionsList[index].frequency,
                      );
                    },
                  ),
                  TextField(
                    controller: frequencyControllers[index],
                    focusNode: frequencyFocusNode,
                    decoration: InputDecoration(
                        labelText: 'ความถี่', labelStyle: GoogleFonts.prompt()),
                    onChanged: (value) {
                      prescriptionsList[index] = PrescriptionModel(
                        name: prescriptionsList[index].name,
                        quantity: prescriptionsList[index].quantity,
                        frequency: value,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _controller.removePrescriptionFromFirestore(
                                widget.appointmentId, prescriptionsList[index]);

                            setState(() {
                              prescriptionsList.removeAt(index);
                              nameControllers.remove(index);
                              quantityControllers.remove(index);
                              frequencyControllers.remove(index);
                            });
                          }),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 8),
        // ปุ่มเพิ่มยา (แก้ไขโดยเก็บค่าชั่วคราวเพื่อให้ข้อมูลวินิจฉัยและการรักษาไม่หาย)
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              // เก็บค่าปัจจุบันของวินิจฉัยและการรักษาไว้ชั่วคราว
              String currentDiagnosis = diagnosisController.text;
              String currentTreatment = treatmentController.text;
              int newIndex = prescriptions.length;
              prescriptions.add(PrescriptionModel(
                name: 'ชื่อยาใหม่',
                quantity: 'ขนาดยา',
                frequency: 'วิธีใช้ยา',
              ));
              // คืนค่าข้อมูลเดิมกลับไปให้กับ TextEditingController
              diagnosisController.text = currentDiagnosis;
              treatmentController.text = currentTreatment;
            });
          },
          icon: const Icon(Icons.add_circle, color: Color(0xFF3B83F6)),
          label: Text(
            'เพิ่มยา',
            style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: Color(0xFF3B83F6), width: 1),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalRecordForm(
    TextEditingController diagnosisController,
    TextEditingController treatmentController,
    List<PrescriptionModel> prescriptions,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildTextField('วินิจฉัย', diagnosisController),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildTextField('การรักษาและคำแนะนำ', treatmentController),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildPrescriptionSection(prescriptions),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 245,
              height: 40,
              child: ElevatedButton(
                onPressed: () async {
                  // ตรวจสอบ prescriptions ทุกตัว
                  bool isValid = true;
                  for (var prescription in prescriptions) {
                    if (prescription.name.trim().isEmpty ||
                        prescription.name.trim() == 'ชื่อยาใหม่' ||
                        prescription.quantity.trim().isEmpty ||
                        prescription.quantity.trim() == 'ขนาดยา' ||
                        prescription.frequency.trim().isEmpty ||
                        prescription.frequency.trim() == 'วิธีใช้ยา') {
                      isValid = false;
                      break;
                    }
                  }

                  if (!isValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('กรุณากรอกข้อมูลยาให้ครบ')),
                    );
                    return;
                  }

                  MedicalRecordModel record = MedicalRecordModel(
                    id: widget.appointmentId,
                    patientId: widget.patientId,
                    doctorId: widget.doctorId,
                    appointmentId: widget.appointmentId,
                    diagnosis: diagnosisController.text,
                    treatment: treatmentController.text,
                    prescriptions: prescriptions,
                    recordDate: DateTime.now(),
                  );

                  await _controller.saveMedicalRecord(record);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('บันทึกผลการรักษาสำเร็จ')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B83F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                  minimumSize: const Size(245, 40),
                  alignment: Alignment.center,
                ),
                child: Text(
                  'บันทึกผลการรักษา',
                  style: GoogleFonts.prompt(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
