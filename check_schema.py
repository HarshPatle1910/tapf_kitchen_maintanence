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
r = requests.get(f"{url}/rest/v1/tickets?limit=1", headers=headers)
print("Tickets schema check:", r.text)
