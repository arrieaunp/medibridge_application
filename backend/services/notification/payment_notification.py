from .notification_service import NotificationService
from datetime import datetime

class PaymentNotification:
    def __init__(self, db, service_account_file):
        self.notification_service = NotificationService(db, service_account_file)

    def notify_patient_about_payment_due(self, patient_id, amount):
        """🔔 แจ้งเตือนผู้ป่วยเกี่ยวกับค่ารักษาพยาบาลที่ต้องชำระ"""
        patient_doc = self.notification_service.db.collection('User').document(patient_id).get()
        if not patient_doc.exists:
            print(f"❌ ไม่พบผู้ป่วย ID: {patient_id}")
            return

        tokens = patient_doc.to_dict().get('fcm_token', [])
        if not tokens:
            print("⚠️ ไม่มี FCM Token สำหรับผู้ป่วยนี้")
            return

        title = "💳 แจ้งเตือนค่ารักษาพยาบาล"
        body = f"คุณมีค่ารักษาพยาบาลจำนวน {amount} บาท กรุณาชำระเงิน"

        is_sent = self.notification_service.send_fcm_notification(
            tokens=tokens,
            title=title,
            body=body,
            data={"type": "PAYMENT_DUE", "amount": str(amount)},
            role="Patient",
            recipient_id=patient_id
        )

        if is_sent:
            print(f"✅ บันทึกการแจ้งเตือนค่ารักษาพยาบาลสำเร็จใน Firestore")
        else:
            print(f"❌ การส่งแจ้งเตือนล้มเหลว")


    def notify_staff_about_patient_payment(self, patient_id, appointment_id, slip_url):
        """🔔 แจ้งเตือนเจ้าหน้าที่เมื่อผู้ป่วยอัปโหลดสลิปชำระเงิน"""
        print("📡 [DEBUG] เริ่มการแจ้งเตือน Staff")

        # ✅ ค้นหา first_name และ last_name ของผู้ป่วยจาก User
        patient_doc = self.notification_service.db.collection('User').document(patient_id).get()

        if not patient_doc.exists:
            print(f"❌ ไม่พบข้อมูลผู้ป่วยจาก User collection: {patient_id}")
            return

        patient_data = patient_doc.to_dict()
        patient_name = f"{patient_data.get('first_name', 'ไม่ทราบชื่อ')} {patient_data.get('last_name', '')}"
        print(f"👤 [DEBUG] ผู้ป่วย: {patient_name}")

        # ✅ ค้นหา วันเวลานัดหมาย จาก Appointments
        appointment_doc = self.notification_service.db.collection('Appointments').document(appointment_id).get()

        if not appointment_doc.exists:
            print(f"❌ ไม่พบนัดหมาย ID: {appointment_id}")
            return

        appointment_data = appointment_doc.to_dict()

        # 🗓️ จัดรูปแบบวันที่-เวลา
        raw_date = appointment_data.get('appointment_date')
        if isinstance(raw_date, datetime):
            appointment_date = raw_date.strftime('%d %B %Y')  # เช่น 22 กุมภาพันธ์ 2025
        else:
            appointment_date = 'ไม่ระบุวันที่'

        appointment_time = appointment_data.get('appointment_time', 'ไม่ระบุเวลา')

        # ✅ ค้นหา FCM Token ของเจ้าหน้าที่
        staff_docs = self.notification_service.db.collection('User').where('role', '==', 'Staff').stream()
        tokens = []
        for doc in staff_docs:
            tokens.extend(doc.to_dict().get('fcm_token', []))
            print(f"🟡 [DEBUG] Staff FCM Token: {doc.to_dict().get('fcm_token', [])}")

        if not tokens:
            print("⚠️ ไม่มี FCM Token ของเจ้าหน้าที่")
            return

        # 📝 สร้างข้อความแจ้งเตือน
        title = "📩 แจ้งเตือน: ผู้ป่วยอัปโหลดสลิปชำระเงิน"
        body = f"ผู้ป่วย {patient_name} ได้อัปโหลดสลิปสำหรับนัดหมายวันที่ {appointment_date} เวลา {appointment_time}"

        # ✅ ส่งแจ้งเตือนผ่าน FCM
        is_sent = self.notification_service.send_fcm_notification(
            tokens=tokens,
            title=title,
            body=body,
            data={
                "type": "PAYMENT_UPLOAD",
                "patient_id": patient_id,
                "patient_name": patient_name,
                "appointment_date": appointment_date,
                "appointment_time": appointment_time,
                "slip_url": slip_url
            },
            role="Staff",
            recipient_id="all_staff"
        )

        # ✅ บันทึกลง Firestore ใน Notifications
        if is_sent:
            print(f"✅ บันทึกการแจ้งเตือนเจ้าหน้าที่สำเร็จ")
            self.notification_service.db.collection("Notifications").add({
                "title": title,
                "body": body,
                "data": {
                    "type": "PAYMENT_UPLOAD",
                    "patient_id": patient_id,
                    "patient_name": patient_name,
                    "appointment_date": appointment_date,
                    "appointment_time": appointment_time,
                    "slip_url": slip_url
                },
                "role": "Staff",
                "recipient_id": "all_staff",
                "timestamp": datetime.now()
            })
        else:
            print(f"❌ การแจ้งเตือนเจ้าหน้าที่ล้มเหลว")
            
    def notify_patient_about_payment_status(self, patient_id, appointment_id, status):
        """🔔 แจ้งเตือนผู้ป่วยเมื่อเจ้าหน้าที่ยืนยันหรือปฏิเสธการชำระเงิน"""

        # ✅ ดึงข้อมูลวันและเวลานัดหมายจาก Firestore
        appointment_doc = self.notification_service.db.collection('Appointments').document(appointment_id).get()
        if not appointment_doc.exists:
            print(f"❌ ไม่พบนัดหมาย ID: {appointment_id}")
            return

        appointment_data = appointment_doc.to_dict()
        # 🗓️ จัดรูปแบบวันที่ให้สวยงาม
        raw_date = appointment_data.get('appointment_date')
        if isinstance(raw_date, datetime):
            appointment_date = raw_date.strftime('%d %B %Y')  # เช่น 22 กุมภาพันธ์ 2025
        else:
            appointment_date = 'ไม่ระบุวันที่'

        appointment_time = appointment_data.get('appointment_time', 'ไม่ระบุเวลา')


        # ✅ ดึง FCM Token ของผู้ป่วย
        patient_doc = self.notification_service.db.collection('User').document(patient_id).get()
        if not patient_doc.exists:
            print(f"❌ ไม่พบผู้ป่วย ID: {patient_id}")
            return

        tokens = patient_doc.to_dict().get('fcm_token', [])
        if not tokens:
            print("⚠️ ไม่มี FCM Token สำหรับผู้ป่วยนี้")
            return

        # 📩 สร้างข้อความแจ้งเตือน
        title = "💳 สถานะการชำระเงิน"
        body = f"สถานะการชำระเงินสำหรับนัดหมายวันที่ {appointment_date} เวลา {appointment_time}: {status}"

        # 🚀 ส่งแจ้งเตือนผ่าน FCM
        is_sent = self.notification_service.send_fcm_notification(
            tokens=tokens,
            title=title,
            body=body,
            data={
                "type": "PAYMENT_STATUS",
                "appointment_id": appointment_id,
                "appointment_date": str(appointment_date),
                "appointment_time": str(appointment_time),
                "status": status
            },
            role="Patient",
            recipient_id=patient_id
        )

        if is_sent:
            print(f"✅ แจ้งเตือนผู้ป่วยสำเร็จ")
        else:
            print(f"❌ แจ้งเตือนผู้ป่วยล้มเหลว")
