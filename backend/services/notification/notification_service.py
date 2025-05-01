import json
import requests
from firebase_admin import firestore
from google.auth.transport.requests import Request
from google.oauth2 import service_account

class NotificationService:
    def __init__(self, db, service_account_file):
        self.db = db
        self.service_account_file = service_account_file
        self.SCOPES = ["https://www.googleapis.com/auth/cloud-platform"]
        self.credentials = service_account.Credentials.from_service_account_file(
            self.service_account_file, scopes=self.SCOPES
        )
    
    def _get_access_token(self):
        """🔐 สร้าง Access Token สำหรับ Firebase Cloud Messaging"""
        self.credentials.refresh(Request())
        return self.credentials.token
    
    def _log_notification(self, recipient_id, role, title, body):
        print(f"📝 [DEBUG] กำลังบันทึกแจ้งเตือนลง Firestore -> recipient_id: {recipient_id}, role: {role}")

        """📜 บันทึกแจ้งเตือนลง Firestore"""
        try:
            self.db.collection('Notifications').add({
                "recipient_id": recipient_id,
                "role": role,
                "title": title,
                "body": body,
                "timestamp": firestore.SERVER_TIMESTAMP
            })
            print(f"✅ บันทึกการแจ้งเตือนสำเร็จ: {title}")
        except Exception as e:
            print(f"❌ ล้มเหลวในการบันทึกการแจ้งเตือน: {e}")

    def send_fcm_notification(self, tokens, title, body, data=None, role=None, recipient_id=None):
        print(f"📡 [DEBUG] เรียก send_fcm_notification สำหรับ {role} - recipient_id: {recipient_id}")
        print(f"📨 [DEBUG] กำลังส่งไปยัง FCM Token: {tokens}")
        
        """🚀 ส่ง FCM Notification"""
        if not tokens:
            print("⚠️ ไม่มี FCM token ที่สามารถใช้ได้")
            return False

        # 🔍 ตรวจสอบ Token และส่งแจ้งเตือน
        access_token = self._get_access_token()
        valid_tokens = []
        invalid_tokens = []

        for token in tokens:
            payload = {
                "message": {
                    "token": token,
                    "notification": {"title": title, "body": body},
                    "data": data or {},
                    "android": {"priority": "high"}
                }
            }

            response = requests.post(
                "https://fcm.googleapis.com/v1/projects/medi-bridge-app/messages:send",
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "Content-Type": "application/json",
                },
                json=payload,
            )

            if response.status_code == 200:
                print(f"✅ FCM ส่งสำเร็จ: {token}")
                valid_tokens.append(token)
            else:
                print(f"⚠️ FCM Error: {response.text}")
                invalid_tokens.append(token)

        # 🧹 ลบ Token ที่ใช้ไม่ได้
        if invalid_tokens:
            user_docs = self.db.collection('User').where('fcm_token', 'array_contains_any', invalid_tokens).stream()
            for doc in user_docs:
                user_id = doc.id
                current_tokens = doc.to_dict().get('fcm_token', [])
                updated_tokens = [t for t in current_tokens if t not in invalid_tokens]
                self.db.collection('User').document(user_id).update({"fcm_token": updated_tokens})
                print(f"🧹 อัปเดต FCM Token สำหรับ User: {user_id}")

        if not valid_tokens:
            print("❌ ไม่มี FCM Token ที่ใช้งานได้")
            return False
        
        self.db.collection("Notifications").add({
            "title": title,
            "body": body,
            "data": data or {},
            "role": role or "Unknown",
            "recipient_id": recipient_id or "Unknown",
            "timestamp": firestore.SERVER_TIMESTAMP
        })
        print(f"📝 บันทึกแจ้งเตือนลง Firestore สำหรับ {role} สำเร็จ")
        return True
    
    def send_fcm_v1(self, payload):
        """🚀 ส่ง FCM ผ่าน Firebase Cloud Messaging v1 API"""
        access_token = self._get_access_token()

        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }

        response = requests.post(
            "https://fcm.googleapis.com/v1/projects/medi-bridge-app/messages:send",
            headers=headers,
            json=payload
        )
        print(f"📡 [DEBUG] FCM Response: {response.status_code} -> {response.text}")
        return response

    
    
