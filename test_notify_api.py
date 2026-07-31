import requests, json
from dotenv import load_dotenv
import os

load_dotenv()
api_key = os.getenv('NOTIFICATION_API_KEY')
url = 'https://tapfkitchenmaintanancebackend-production.up.railway.app/api/notifications/trigger'

payload = {
    "action": "TEST",
    "ticket_id": "00000000-0000-0000-0000-000000000000",
    "ticket_no": "TEST-123",
    "kitchen_id": "00000000-0000-0000-0000-000000000000"
}
headers = {
    'Content-Type': 'application/json',
    'x-api-key': api_key
}
r = requests.post(url, json=payload, headers=headers)
print("Status:", r.status_code)
print("Body:", r.text)
