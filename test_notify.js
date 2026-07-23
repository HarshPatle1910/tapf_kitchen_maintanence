const url = 'https://sfjjxmdkdswothebcbbd.supabase.co';
const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNmamp4bWRrZHN3b3RoZWJjYmJkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NjQ4ODY2MiwiZXhwIjoyMDkyMDY0NjYyfQ.Hq5JcUcRRHXfNjtRCXPKYIL_zfGhwH_bwgV6YgFITi8';

async function run() {
  const tRes = await fetch(`${url}/rest/v1/tickets?select=id,ticket_no&order=created_at.desc&limit=1`, {
    headers: {
      'apikey': key,
      'Authorization': `Bearer ${key}`
    }
  });
  const tickets = await tRes.json();
  
  if (!tickets || tickets.length === 0) {
    console.log('No tickets found');
    return;
  }
  const ticketId = tickets[0].id;
  console.log('Found latest ticket:', tickets[0].ticket_no, ticketId);
  
  const response = await fetch(`${url}/functions/v1/telegram-notify`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${key}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      type: 'INSERT',
      record: { id: ticketId }
    })
  });
  
  const text = await response.text();
  console.log('Edge function response status:', response.status);
  console.log('Edge function response text:', text);
}
run();
