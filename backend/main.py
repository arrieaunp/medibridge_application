# main.py
from flask import Flask, request, jsonify
from firebase_admin import credentials, firestore, messaging
from services.notification.schedule_notification import ScheduleNotification
from services.notification.payment_notification import PaymentNotification
from services.notification.notification_service import NotificationService
from services.notification.appointment_notification import AppointmentNotification
from datetime import datetime
import firebase_admin
from apscheduler.schedulers.background import BackgroundScheduler
import atexit

# ✅ Initialize Firebase
service_account_path = "config/medi-bridge-app-firebase-adminsdk-iew3q-c1f0b31f28.json"
cred = credentials.Certificate(service_account_path)
firebase_admin.initialize_app(cred)
# ใช้ firestore.Client.from_service_account_json เพื่อเชื่อมต่อ (ตรวจสอบ path ให้ถูกต้อง)
db = firestore.Client.from_service_account_json(service_account_path)

# ✅ สร้าง Notification Services
notification_service = NotificationService(db, service_account_path)
appointment_notification = AppointmentNotification(db, service_account_path)
payment_notification = PaymentNotification(db, service_account_path)
schedule_notification = ScheduleNotification(db, service_account_path)

# นำเข้าฟังก์ชันสำหรับแจ้งเตือนนัดหมายล่วงหน้า (Background Job)
from services.notification.notify_upcoming_appointments import notify_appointments_tomorrow

app = Flask(__name__)

# ตั้งค่า APScheduler ให้รัน notify_appointments_tomorrow ทุกวันตอน 8:00 AM
scheduler = BackgroundScheduler()
scheduler.add_job(func=notify_appointments_tomorrow, trigger='cron', hour=8, minute=0)
scheduler.start()
atexit.register(lambda: scheduler.shutdown())

# =================== Routes ===================

@app.route('/new-appointment-notification', methods=['POST'])
def new_appointment_notification():
    try:
        data = request.json
        appointment_id = data.get('appointment_id')
        title = data.get('title')
        body = data.get('body')

        # ✅ ดึง FCM Tokens ของ Staff
        staff_docs = db.collection('User').where('role', '==', 'Staff').stream()
        tokens = []
        for doc in staff_docs:
            user_data = doc.to_dict()
            tokens.extend(user_data.get('fcm_token', []))

        if not tokens:
            return jsonify({"success": False, "error": "No valid FCM tokens found"}), 400

        # ✅ ส่ง Notification และบันทึกลง Firestore
        notification_service.send_fcm_notification(
            tokens,
            title,
            body,
            {"appointment_id": appointment_id, "type": "NEW_APPOINTMENT"},
            role="Staff",
            recipient_id="all_staff"
        )

        return jsonify({"success": True, "message": "Notification sent to staff"}), 200

    except Exception as e:
        print(f"❌ Exception: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/appointment-status-notification', methods=['POST'])
def appointment_status_notification():
    try:
        data = request.json
        patient_id = data.get('patient_id')
        doctor_id = data.get('doctor_id')
        status = data.get('status')
        appointment_date = data.get('appointment_date')
        appointment_time = data.get('appointment_time')

        if not patient_id or not doctor_id or not appointment_date or not appointment_time:
            return jsonify({"success": False, "error": "Missing required fields"}), 400

        # ส่งแจ้งเตือนและบันทึก
        appointment_notification.notify_patient_about_appointment_status(
            patient_id, status, appointment_date, appointment_time
        )
        appointment_notification.notify_doctor_about_appointment_status(
            doctor_id, status, appointment_date, appointment_time
        )

        return jsonify({"success": True, "message": "Notification sent to patient and doctor"}), 200

    except Exception as e:
        print(f"❌ Error: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/payment-due-notification', methods=['POST'])
def payment_due_notification():
    try:
        data = request.json
        patient_id = data.get('patient_id')
        amount = data.get('amount')

        if not patient_id or not amount:
            return jsonify({"success": False, "error": "Missing required fields"}), 400

        payment_notification.notify_patient_about_payment_due(patient_id, amount)
        return jsonify({"success": True, "message": "Payment due notification sent to patient"}), 200

    except Exception as e:
        print(f"❌ Error: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/notify-staff-payment-upload', methods=['POST'])
def notify_staff_payment_upload():
    try:
        data = request.json
        appointment_id = data.get('appointment_id')
        patient_id = data.get('patient_id')
        slip_url = data.get('slip_url')

        if not appointment_id or not patient_id or not slip_url:
            return jsonify({"success": False, "error": "Missing required fields"}), 400

        payment_notification.notify_staff_about_patient_payment(patient_id, appointment_id, slip_url)
        return jsonify({"success": True, "message": "Notification sent to staff"}), 200

    except Exception as e:
        print(f"❌ Error: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/notify-payment-status', methods=['POST'])
def notify_payment_status():
    try:
        data = request.json
        patient_id = data.get('patient_id')
        appointment_id = data.get('appointment_id')
        status = data.get('status')

        payment_notification.notify_patient_about_payment_status(patient_id, appointment_id, status)
        return jsonify({"success": True, "message": "Notification sent to patient"}), 200
    except Exception as e:
        print(f"❌ Error: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/notify-schedule-change-request', methods=['POST'])
def notify_schedule_change_request():
    try:
        data = request.json
        doctor_id = data.get('doctor_id')
        schedule_date_str = data.get('schedule_date')
        schedule_time = data.get('schedule_time')
        reason = data.get('reason')

        if not doctor_id or not schedule_date_str or not schedule_time or not reason:
            return jsonify({"success": False, "error": "Missing required fields"}), 400

        try:
            schedule_date = datetime.fromisoformat(schedule_date_str)
        except ValueError:
            return jsonify({"success": False, "error": "Invalid date format"}), 400

        staff_success = schedule_notification.notify_staff_about_schedule_change_request(
            doctor_id, schedule_date, schedule_time, reason
        )
        doctor_success = schedule_notification.notify_doctor_about_request_submission(
            doctor_id, schedule_date.strftime('%d %B %Y'), schedule_time
        )

        if staff_success and doctor_success:
            return jsonify({"success": True, "message": "Notification sent to staff and doctor"}), 200
        elif staff_success:
            return jsonify({"success": False, "message": "Sent to staff only, doctor notification failed"}), 207
        elif doctor_success:
            return jsonify({"success": False, "message": "Sent to doctor only, staff notification failed"}), 207
        else:
            return jsonify({"success": False, "message": "Failed to send notifications"}), 500

    except Exception as e:
        print(f"❌ Error: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/notify-doctor-schedule-updated', methods=['POST'])
def notify_doctor_schedule_updated():
    try:
        data = request.json
        doctor_id = data.get('doctor_id')
        schedule_date_str = data.get('schedule_date')
        start_time = data.get('start_time')
        end_time = data.get('end_time')

        if not doctor_id or not schedule_date_str or not start_time or not end_time:
            return jsonify({"success": False, "error": "Missing required fields"}), 400

        try:
            schedule_date = datetime.fromisoformat(schedule_date_str)
        except ValueError:
            return jsonify({"success": False, "error": "Invalid date format"}), 400

        doctor_doc = db.collection('User').document(doctor_id).get()
        if not doctor_doc.exists:
            return jsonify({"success": False, "error": "Doctor not found"}), 404

        doctor_data = doctor_doc.to_dict()
        fcm_tokens = doctor_data.get('fcm_token', [])
        if not fcm_tokens:
            print(f"⚠️ ไม่มี FCM token สำหรับแพทย์ {doctor_id}")
            return jsonify({"success": False, "error": "No FCM tokens found"}), 400

        title = "📅 ตารางเวรถูกเปลี่ยนแปลง"
        body = (
            f"ตารางเวรของคุณถูกเปลี่ยนเป็น "
            f"วันที่ {schedule_date.strftime('%d %B %Y')} "
            f"เวลา {start_time} - {end_time} "
            "โปรดตรวจสอบรายละเอียด"
        )

        notification_service.send_fcm_notification(
            fcm_tokens,
            title,
            body,
            {
                "type": "SCHEDULE_UPDATED",
                "schedule_date": schedule_date.strftime('%Y-%m-%d'),
                "start_time": start_time,
                "end_time": end_time,
            },
            role="Doctor",
            recipient_id=doctor_id
        )

        # db.collection("Notifications").add({
        #     "recipient_id": doctor_id,
        #     "role": "Doctor",
        #     "title": title,
        #     "body": body,
        #     "timestamp": datetime.now(),
        #     "type": "SCHEDULE_UPDATED",
        #     "status": "sent"
        # })

        print(f"✅ แจ้งเตือนแพทย์ {doctor_id} สำเร็จ และบันทึกใน Firestore")
        return jsonify({"success": True, "message": "Notification sent to doctor"}), 200

    except Exception as e:
        print(f"❌ Error: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

# =================== End Routes ===================

if __name__ == "__main__":
    print("🚀 Starting Flask Server with APScheduler...")
    app.run(host="0.0.0.0", port=5001, debug=True)
