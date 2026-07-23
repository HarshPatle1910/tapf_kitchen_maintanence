const url = 'https://sfjjxmdkdswothebcbbd.supabase.co';
const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNmamp4bWRrZHN3b3RoZWJjYmJkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NjQ4ODY2MiwiZXhwIjoyMDkyMDY0NjYyfQ.Hq5JcUcRRHXfNjtRCXPKYIL_zfGhwH_bwgV6YgFITi8';
fetch(url + '/rest/v1/m_zone?select=id,name,telegram_chat_id', {
  headers: { 'apikey': key, 'Authorization': 'Bearer ' + key }
}).then(r => r.json()).then(console.log).catch(console.error);
