from datetime import datetime
from services.notification.notification_service import NotificationService

class ScheduleNotification:
    def __init__(self, db, service_account_file):
        self.db = db
        self.notification_service = NotificationService(db, service_account_file)

    def notify_staff_about_schedule_change_request(self, doctor_id, schedule_date, schedule_time, reason):
        """🔔 แจ้งเตือนเจ้าหน้าที่เมื่อแพทย์ส่งคำร้องขอเปลี่ยนตารางเวร"""
        try:
            # ✅ 1. ค้นหาชื่อแพทย์จาก User collection
            doctor_doc = self.db.collection('User').document(doctor_id).get()
            if not doctor_doc.exists:
                print(f"⚠️ ไม่พบข้อมูลแพทย์สำหรับ doctor_id: {doctor_id}")
                doctor_name = f"แพทย์ (รหัส: {doctor_id})"
            else:
                doctor_data = doctor_doc.to_dict()
                first_name = doctor_data.get('first_name', 'ไม่ทราบชื่อ')
                last_name = doctor_data.get('last_name', 'ไม่ทราบนามสกุล')
                doctor_name = f"แพทย์ {first_name} {last_name}"

            # ✅ 2. จัดรูปแบบวันที่
            if isinstance(schedule_date, datetime):  # ✅ แก้ไขตรงนี้
                formatted_date = schedule_date.strftime('%d %B %Y')  # ✅ เช่น "17 กุมภาพันธ์ 2025"
            else:
                formatted_date = 'ไม่ระบุวันที่'

            formatted_time = schedule_time if schedule_time else "ไม่ระบุเวลา"

            # ✅ 3. ดึง FCM Tokens ของเจ้าหน้าที่
            staff_docs = self.db.collection('User').where('role', '==', 'Staff').stream()
            tokens = []
            for doc in staff_docs:
                user_data = doc.to_dict()
                tokens.extend(user_data.get('fcm_token', []))

            if not tokens:
                print("⚠️ ไม่มี FCM token ของเจ้าหน้าที่")
                return False

            # ✅ 4. ปรับเนื้อหาแจ้งเตือนเป็นชื่อแพทย์
            title = "📅 คำร้องขอเปลี่ยนตารางเวร"
            body = (
                f"{doctor_name} ขอเปลี่ยนตารางเวร "
                f"วันที่ {formatted_date} เวลา {formatted_time} "
                f"เหตุผล: {reason}"
            )

            # ✅ 5. ส่งแจ้งเตือนผ่าน FCM
            self.notification_service.send_fcm_notification(
                tokens,
                title,
                body,
                {
                    "type": "SCHEDULE_CHANGE_REQUEST",
                    "doctor_name": doctor_name,
                    "schedule_date": formatted_date,
                    "schedule_time": formatted_time,
                },
                role="Staff",
                recipient_id="all_staff"
            )

            print("✅ แจ้งเตือนคำร้องขอเปลี่ยนตารางเวรสำเร็จ")
            return True

        except Exception as e:
            print(f"❌ เกิดข้อผิดพลาดในการแจ้งเตือน: {e}")
            return False

    def notify_doctor_about_request_submission(self, doctor_id, schedule_date, schedule_time):
        """🔔 แจ้งเตือนแพทย์เมื่อส่งคำขอเปลี่ยนตารางเวรสำเร็จ"""
        try:
            # ✅ 1. ดึง FCM Token ของแพทย์
            doctor_doc = self.db.collection('User').document(doctor_id).get()
            if not doctor_doc.exists:
                print(f"⚠️ ไม่พบข้อมูลแพทย์สำหรับ doctor_id: {doctor_id}")
                return False

            doctor_data = doctor_doc.to_dict()
            tokens = doctor_data.get('fcm_token', [])

            if not tokens:
                print(f"⚠️ ไม่มี FCM token ของแพทย์ {doctor_id}")
                return False

            # ✅ 2. สร้างข้อความแจ้งเตือน
            title = "📨 คำขอเปลี่ยนตารางเวรถูกส่งแล้ว"
            body = (
                f"คำขอเปลี่ยนตารางเวรของคุณถูกส่งสำเร็จ "
                f"วันที่ {schedule_date} เวลา {schedule_time} "
                "กรุณารอการตรวจสอบจากเจ้าหน้าที่"
            )

            # ✅ 3. ส่งแจ้งเตือน FCM
            self.notification_service.send_fcm_notification(
                tokens,
                title,
                body,
                {
                    "type": "SCHEDULE_REQUEST_SUBMITTED",
                    "schedule_date": schedule_date,
                    "schedule_time": schedule_time,
                    "status": "pending"
                },
                role="Doctor",
                recipient_id=doctor_id
            )

            # # ✅ 4. บันทึกลง Firestore (Notifications Collection)
            # self.db.collection("Notifications").add({
            #     "recipient_id": doctor_id,
            #     "role": "Doctor",
            #     "title": title,
            #     "body": body,
            #     "timestamp": datetime.now(),
            #     "type": "SCHEDULE_REQUEST_SUBMITTED",
            #     "status": "sent"
            # })

            print(f"✅ แจ้งเตือนแพทย์ {doctor_id} สำเร็จ")
            return True

        except Exception as e:
            print(f"❌ แจ้งเตือนแพทย์ล้มเหลว: {e}")
            return False
