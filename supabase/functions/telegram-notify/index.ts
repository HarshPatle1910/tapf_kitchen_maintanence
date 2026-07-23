import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

// Environment variables provided by Supabase
const TELEGRAM_BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN")!;
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(supabaseUrl, supabaseServiceKey);
const STORAGE_BUCKET_NAME = "ticket-media"; // Ensure this matches your bucket!

// HELPER: Safely escape HTML characters to prevent Telegram parse errors
function escapeHtml(text: string | null | undefined): string {
  if (!text) return 'N/A';
  return text.toString()
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
    // FIX: Removed the &#039; replacement because Telegram does not support it!
}

serve(async (req) => {
  try {
    const payload = await req.json();
    const record = payload.record || payload.new || payload;
    const oldRecord = payload.old_record || payload.old || {};
    const type = payload.type || (payload.record ? "INSERT" : "UPDATE");

    console.log(`📩 Webhook Triggered! Type: ${type}, Record ID: ${record?.id}`);

    if (!record || !record.id) {
      console.log("⚠️ No record or record.id found in payload");
      return new Response("No valid record ID found in payload", { status: 200 });
    }

    if (type === "UPDATE") {
      if (oldRecord.status === "COMPLETED" || record.status !== "COMPLETED") {
        console.log(`ℹ️ Status change ignored: old=${oldRecord.status}, new=${record.status}`);
        return new Response("Not a triggerable status change", { status: 200 });
      }
    }

    // Race Condition Delay (Wait for mobile app to upload images)
    console.log("⏳ Waiting 4 seconds for mobile app to finish image uploads...");
    await new Promise(resolve => setTimeout(resolve, 4000));

    // 1. Fetch ticket data safely without fragile relation hints (NO ticket_media or m_zone nesting)
    const { data: ticketInfo, error } = await supabase
      .from("tickets")
      .select(`
        id,
        ticket_no,
        title,
        priority,
        raised_by_id,
        assigned_to_id,
        area_id,
        m_kitchen (name),
        m_area (
          area_name,
          zone_id
        )
      `)
      .eq("id", record.id)
      .single();

    if (error || !ticketInfo) {
      console.error(`❌ Error fetching ticket info for ID ${record.id}:`, error);
      throw error || new Error("Ticket not found");
    }

    // Fetch user names independently to avoid join crashes when fields are null
    let raisedByName = 'N/A';
    if (ticketInfo.raised_by_id) {
      const { data: u } = await supabase.from("m_user").select("name").eq("id", ticketInfo.raised_by_id).maybeSingle();
      if (u?.name) raisedByName = u.name;
    }

    let assignedToName = 'Unknown Worker';
    if (ticketInfo.assigned_to_id) {
      const { data: u } = await supabase.from("m_user").select("name").eq("id", ticketInfo.assigned_to_id).maybeSingle();
      if (u?.name) assignedToName = u.name;
    }

    // Fetch m_zone independently to ensure we get the telegram_chat_id properly without PostgREST bugs
    let rawChatId = null;
    let zoneName = 'Unknown Zone';
    
    if (ticketInfo.m_area && ticketInfo.m_area.zone_id) {
      const { data: zoneData, error: zoneError } = await supabase
        .from("m_zone")
        .select("name, telegram_chat_id")
        .eq("id", ticketInfo.m_area.zone_id)
        .maybeSingle();
        
      if (zoneData) {
        zoneName = zoneData.name || 'Unknown Zone';
        rawChatId = zoneData.telegram_chat_id;
      }
    }

    if (!rawChatId) {
      console.log("⚠️ No Telegram Chat ID mapped for zone:", zoneName);
      return new Response("No Chat ID mapped", { status: 200 });
    }

    const cleanChatId = String(rawChatId).trim().replace(/['"\s\n\r]/g, '');

    // 2. Format the Text Message using HTML instead of Markdown
    let messageText = "";
    if (type === "INSERT") {
      const priorityAlert = ticketInfo.priority === 'CRITICAL' ? '🚨🚨🚨' : '⚠️';
      messageText = `${priorityAlert} <b>NEW TICKET RAISED</b> ${priorityAlert}\n\n`;
      messageText += `<b>Ticket No:</b> ${escapeHtml(ticketInfo.ticket_no)}\n`;
      messageText += `<b>Priority:</b> ${escapeHtml(ticketInfo.priority)}\n`;
      messageText += `<b>Issue:</b> ${escapeHtml(ticketInfo.title)}\n`;
      messageText += `<b>Location:</b> ${escapeHtml(ticketInfo.m_kitchen?.name)} ➡️ ${escapeHtml(zoneName)} ➡️ ${escapeHtml(ticketInfo.m_area?.area_name)}\n`;
      messageText += `<b>Raised By:</b> ${escapeHtml(raisedByName)}\n`;
    } else if (type === "UPDATE" && record.status === "COMPLETED") {
      messageText = `✅ <b>TICKET COMPLETED</b> ✅\n\n`;
      messageText += `<b>Ticket No:</b> ${escapeHtml(ticketInfo.ticket_no)}\n`;
      messageText += `<b>Issue:</b> ${escapeHtml(ticketInfo.title)}\n`;
      messageText += `<b>Location:</b> ${escapeHtml(ticketInfo.m_kitchen?.name)} ➡️ ${escapeHtml(zoneName)}\n`;
      messageText += `<b>Fixed By:</b> ${escapeHtml(assignedToName)}\n`;
    }

    // Fetch ticket_media independently to avoid PostgREST nested join bugs (column missing errors)
    const { data: ticketMediaRecords, error: mediaError } = await supabase
      .from("ticket_media")
      .select("media_url, media_type, upload_stage, created_at")
      .eq("ticket_id", record.id);
      
    if (mediaError) {
      console.warn("⚠️ Error fetching ticket media:", mediaError);
    }
    const ticketMedia = ticketMediaRecords || [];

    // 3. Process Images: Smart Selection
    let targetPhotos: any[] = [];
    const allPhotos = ticketMedia.filter((m: any) => m.media_type === 'photo');

    if (allPhotos.length > 0) {
      if (type === "INSERT") {
        targetPhotos = allPhotos.filter(m => m.upload_stage !== 'COMPLETED');
      }
      else if (type === "UPDATE") {
        targetPhotos = allPhotos.filter(m => m.upload_stage === 'COMPLETED');

        if (targetPhotos.length === 0) {
          const newestTime = Math.max(...allPhotos.map(p => new Date(p.created_at).getTime()));
          targetPhotos = allPhotos.filter(p => new Date(p.created_at).getTime() > newestTime - 60000);
        }
      }
    }

    // 4. Collect Media URLs for all target photos
    const photoUrls: string[] = [];
    for (const photo of targetPhotos) {
      if (photo.media_url) {
        photoUrls.push(photo.media_url);
      }
    }

    // 5. Send to Telegram API (Dynamically handling 0, 1, or Multiple images)
    let tgUrl = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
    let tgPayload: any = { chat_id: cleanChatId };

    if (photoUrls.length === 1) {
      // EXACTLY ONE IMAGE -> Use sendPhoto
      tgUrl = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendPhoto`;
      tgPayload.photo = photoUrls[0];
      tgPayload.caption = messageText;
      tgPayload.parse_mode = "HTML";
    }
    else if (photoUrls.length > 1) {
      // MULTIPLE IMAGES -> Use sendMediaGroup (Album)
      tgUrl = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMediaGroup`;

      tgPayload.media = photoUrls.map((url, index) => {
        const mediaObj: any = { type: "photo", media: url };
        if (index === 0) {
          mediaObj.caption = messageText;
          mediaObj.parse_mode = "HTML";
        }
        return mediaObj;
      });
    }
    else {
      // ZERO IMAGES -> Use sendMessage (Text only)
      tgPayload.text = messageText;
      tgPayload.parse_mode = "HTML";
    }

    let tgResponse = await fetch(tgUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(tgPayload),
    });

    // FALLBACK: If sending with image fails (e.g. invalid photo URL or Telegram download error), fallback to text-only sendMessage
    if (!tgResponse.ok && (tgUrl.includes("sendPhoto") || tgUrl.includes("sendMediaGroup"))) {
      console.warn("⚠️ Failed to send photo/album to Telegram. Falling back to text-only sendMessage...");
      const fallbackUrl = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
      const fallbackPayload = {
        chat_id: cleanChatId,
        text: messageText,
        parse_mode: "HTML",
      };
      tgResponse = await fetch(fallbackUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(fallbackPayload),
      });
    }

    if (!tgResponse.ok) {
      const tgError = await tgResponse.text();
      console.error(`❌ Telegram API Error: ${tgError}`);
      throw new Error(`Telegram API Error: ${tgError}`);
    }

    return new Response(JSON.stringify({ success: true, imageCount: photoUrls.length }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });

  } catch (err) {
    console.error("Function Error:", err);
    return new Response(JSON.stringify({ error: err instanceof Error ? err.message : "Unknown error" }), { 
      headers: { "Content-Type": "application/json" },
      status: 500 
    });
  }
});