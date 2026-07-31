# Python Backend Snippet

This snippet shows how to update your Railway Python backend to handle threaded replies and extract the `message_id` from Telegram.

```python
import os
import requests
from fastapi import FastAPI, Request
from supabase import create_client, Client

app = FastAPI()

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") # Or Anon Key depending on RLS
TELEGRAM_BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN")
TELEGRAM_CHAT_ID = os.environ.get("TELEGRAM_CHAT_ID") # e.g., "-100123456789"

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

@app.post("/api/notifications/trigger")
async def trigger_notification(request: Request):
    payload = await request.json()
    action = payload.get("action", "UPDATE") # e.g., "RAISED" or "VERIFIED"
    ticket_id = payload.get("ticket_id")
    telegram_message_id = payload.get("telegram_message_id")
    
    # 1. Fetch images from Supabase (if any)
    media_res = supabase.table("ticket_media").select("media_url").eq("ticket_id", ticket_id).execute()
    photo_urls = [m["media_url"] for m in media_res.data] if media_res.data else []

    # 2. Prepare Telegram payload
    tg_payload = {
        "chat_id": TELEGRAM_CHAT_ID,
        "parse_mode": "HTML",
    }
    
    # Text content (Build your message here)
    message_text = f"<b>Ticket {action}</b>\nTicket ID: {payload.get('ticket_no')}"
    
    # ADD THREADED REPLY LOGIC
    # If this is an update and we have the original message ID, thread it!
    if action != "RAISED" and telegram_message_id:
        tg_payload["reply_parameters"] = {"message_id": int(telegram_message_id)}

    # 3. Send to Telegram
    base_url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}"
    
    if len(photo_urls) == 0:
        # Text Only
        tg_payload["text"] = message_text
        tg_response = requests.post(f"{base_url}/sendMessage", json=tg_payload)
        
    elif len(photo_urls) == 1:
        # Single Photo
        tg_payload["caption"] = message_text
        tg_payload["photo"] = photo_urls[0]
        tg_response = requests.post(f"{base_url}/sendPhoto", json=tg_payload)
        
    else:
        # Multiple Photos (MediaGroup)
        media = []
        for i, url in enumerate(photo_urls):
            media_item = {"type": "photo", "media": url}
            if i == 0:
                media_item["caption"] = message_text
                media_item["parse_mode"] = "HTML"
            media.append(media_item)
            
        tg_payload["media"] = media
        tg_response = requests.post(f"{base_url}/sendMediaGroup", json=tg_payload)

    # 4. Extract message_id from Telegram response
    tg_data = tg_response.json()
    sent_message_id = None
    
    if tg_response.status_code == 200 and "result" in tg_data:
        if isinstance(tg_data["result"], list):
            sent_message_id = tg_data["result"][0].get("message_id")
        else:
            sent_message_id = tg_data["result"].get("message_id")
            
    # 5. Return it to Flutter!
    # By returning this, the Flutter app will automatically save it to the tickets table.
    return {
        "success": True,
        "message_id": sent_message_id,
        "raw_telegram_response": tg_data
    }
```
