import firebase_admin
from firebase_admin import credentials, firestore, messaging
import datetime

# ตรวจสอบว่ามี Firebase app อยู่แล้วหรือไม่
try:
    firebase_admin.get_app()
except ValueError:
    cred = credentials.Certificate("config/medi-bridge-app-firebase-adminsdk-iew3q-c1f0b31f28.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

def notify_appointments_tomorrow():
    now = datetime.datetime.now()
    tomorrow = now + datetime.timedelta(days=1)
    start = datetime.datetime(tomorrow.year, tomorrow.month, tomorrow.day, 0, 0)
    end = datetime.datetime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59)
    
    appointments_ref = db.collection('Appointments')
    query = appointments_ref \
        .where('appointment_date', '>=', start) \
        .where('appointment_date', '<=', end)
    appointments = query.stream()
    
    for doc in appointments:
        data = doc.to_dict()
        patient_id = data.get('patient_id')
        appointment_time = data.get('appointment_time')
    
        user_doc = db.collection('User').document(patient_id).get()
        if user_doc.exists:
            user_data = user_doc.to_dict()
            fcm_token = user_data.get('fcm_token')
            tokens = []
            if isinstance(fcm_token, list):
                tokens = fcm_token
            elif isinstance(fcm_token, str):
                tokens = [fcm_token]
    
            if tokens:
                for token in tokens:
                    if token and token.strip():
                        try:
                            messaging.send(
                                messaging.Message(
                                    token=token,
                                    notification=messaging.Notification(
                                        title='แจ้งเตือนนัดหมาย',
                                        body=f'คุณมีนัดหมายในวันพรุ่งนี้ เวลา {appointment_time}'
                                    )
                                )
                            )
                            print(f"✅ แจ้งเตือนผู้ใช้ {patient_id} สำหรับ token {token} เรียบร้อย")
                        except messaging.UnregisteredError:
                            print(f"⚠️ Token {token} หมดอายุหรือไม่ถูกต้อง ข้ามไปเลย")
                        except Exception as e:
                            print(f"❌ ส่งแจ้งเตือน token {token} ผิดพลาด: {e}")
                    else:
                        print(f"⚠️ ข้าม token ว่างของผู้ใช้ {patient_id}")
            else:
                print(f"⚠️ ข้ามผู้ใช้ {patient_id} เพราะไม่มี FCM token")
        else:
            print(f"⚠️ ไม่พบข้อมูลผู้ใช้ {patient_id}")
