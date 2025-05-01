from .notification_service import NotificationService

class AppointmentNotification:
    def __init__(self, db, service_account_file):
        self.notification_service = NotificationService(db, service_account_file)

    def notify_new_appointment(self, appointment_id, appointment_date, appointment_time):
        """🔔 แจ้งเตือนเจ้าหน้าที่เมื่อมีนัดหมายใหม่ และบันทึก"""
        staff_docs = self.notification_service.db.collection('User').where('role', '==', 'Staff').stream()
        tokens = []
        staff_ids = []
        for doc in staff_docs:
            tokens.extend(doc.to_dict().get('fcm_token', []))
            staff_ids.append(doc.id)

        title = "🔔 แจ้งเตือน: นัดหมายใหม่"
        body = f"มีนัดหมายใหม่ วันที่ {appointment_date} เวลา {appointment_time} กรุณาตรวจสอบ"

        # ✅ ส่ง Notification พร้อมบันทึกแจ้งเตือนให้ทุกสตาฟ
        self.notification_service.send_fcm_notification(tokens, title, body, 
            {"appointment_id": appointment_id}, 
            role="Staff", 
            recipient_id="all_staff")

    def notify_patient_about_appointment_status(self, patient_id, status, appointment_date, appointment_time):
        print(f"📌 [DEBUG] กำลังเตรียมส่งแจ้งเตือนให้ผู้ป่วย: {patient_id}")

        """🔔 แจ้งเตือนผู้ป่วยเมื่อสถานะนัดหมายเปลี่ยน"""
        patient_doc = self.notification_service.db.collection('User').document(patient_id).get()
        if not patient_doc.exists:
            print(f"❌ [DEBUG] ไม่พบข้อมูลผู้ป่วยใน Firestore: {patient_id}")
            return

        tokens = patient_doc.to_dict().get('fcm_token', [])
        if not tokens:
            print("⚠️ ไม่มี Token สำหรับผู้ป่วยนี้")
            return

        status_msg = "ได้รับการยืนยันแล้ว" if status == "รอชำระเงิน" else "ถูกยกเลิก"
        title = "🩺 แจ้งเตือน: สถานะนัดหมาย"
        body = f"นัดหมายของคุณ {status_msg} วันที่ {appointment_date} เวลา {appointment_time}"

        # ✅ ส่ง Notification พร้อมบันทึกแจ้งเตือน
        self.notification_service.send_fcm_notification(tokens, title, body, 
            {"status": status}, 
            role="Patient", 
       
            recipient_id=patient_id)
        
    def notify_doctor_about_appointment_status(self, doctor_id, status, appointment_date, appointment_time):
        """🔔 แจ้งเตือนแพทย์เมื่อมีการยืนยันหรือยกเลิกนัดหมาย"""
        print(f"📌 [DEBUG] กำลังเตรียมส่งแจ้งเตือนให้แพทย์: {doctor_id}")

        doctor_doc = self.notification_service.db.collection('User').document(doctor_id).get()
        if not doctor_doc.exists:
            print(f"❌ [DEBUG] ไม่พบข้อมูลแพทย์ใน Firestore: {doctor_id}")
            return

        tokens = doctor_doc.to_dict().get('fcm_token', [])
        if not tokens:
            print("⚠️ ไม่มี Token สำหรับแพทย์นี้")
            return

        status_msg = "ได้รับการยืนยันแล้ว" if status == "รอชำระเงิน" else "ถูกยกเลิก"
        title = "🩺 แจ้งเตือน: สถานะนัดหมาย"
        body = f"นัดหมายของคุณ {status_msg} วันที่ {appointment_date} เวลา {appointment_time}"

        # ✅ ส่ง Notification พร้อมบันทึกแจ้งเตือน
        self.notification_service.send_fcm_notification(tokens, title, body, 
            {"status": status}, 
            role="Doctor", 
            recipient_id=doctor_id)

