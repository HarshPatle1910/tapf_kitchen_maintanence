import requests, json
from dotenv import load_dotenv
import os

load_dotenv()
url = os.getenv('SUPABASE_URL')
key = os.getenv('SUPABASE_ANON_KEY')

headers = {
    'apikey': key,
    'Authorization': f'Bearer {key}'
}
r = requests.get(f"{url}/rest/v1/tickets?select=id,ticket_no,kitchen_id&limit=1", headers=headers)
data = r.json()
print("Tickets:", json.dumps(data))

if data and len(data) > 0:
    ticket = data[0]
    api_key = os.getenv('NOTIFICATION_API_KEY')
    notify_url = 'https://tapfkitchenmaintanancebackend-production.up.railway.app/api/notifications/trigger'
    
    payload = {
        "action": "RAISED",
        "ticket_id": ticket['id'],
        "ticket_no": ticket['ticket_no'],
        "kitchen_id": ticket['kitchen_id']
    }
    notify_headers = {
        'Content-Type': 'application/json',
        'x-api-key': api_key
    }
    res = requests.post(notify_url, json=payload, headers=notify_headers)
    print("Notify Status:", res.status_code)
    print("Notify Body:", res.text)
