import os
import sys
from supabase import create_client

url = "https://sfjjxmdkdswothebcbbd.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNmamp4bWRrZHN3b3RoZWJjYmJkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0ODg2NjIsImV4cCI6MjA5MjA2NDY2Mn0.oFdI4Azq71VjJ7q0BHacOfv88QTKt0tCLVecmngkjrU"

supabase = create_client(url, key)

res = supabase.table("tickets").select("id, ticket_no, m_area(zone_id)").order("updated_at", desc=True).limit(5).execute()
print("Latest tickets:", res.data)

for ticket in res.data:
    if ticket.get("m_area") and ticket["m_area"].get("zone_id"):
        zone_res = supabase.table("m_zone").select("telegram_chat_id").eq("id", ticket["m_area"]["zone_id"]).execute()
        print(f"Zone for ticket {ticket['ticket_no']}: {zone_res.data}")
