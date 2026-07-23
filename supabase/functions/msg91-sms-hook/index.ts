import { Webhook } from "https://esm.sh/standardwebhooks@1.0.0";

// Ensure you set these in your Supabase environment variables later
const MSG91_AUTHKEY = Deno.env.get("MSG91_AUTHKEY")!;
const MSG91_TEMPLATE_ID = Deno.env.get("MSG91_TEMPLATE_ID")!;

Deno.serve(async (req) => {
  const payload = await req.text();
  const headers = Object.fromEntries(req.headers);
  const wh = new Webhook(Deno.env.get("MSG91_WEBHOOK_SECRET")!);

  try {
    // Verify the payload comes securely from Supabase
    const { user, sms } = wh.verify(payload, headers) as {
      user: { phone: string };
      sms: { otp: string };
    };

    // MSG91 requires the country code but usually without the '+' sign
    const cleanPhone = user.phone.replace("+", ""); 
    const otp = sms.otp;

    // MSG91 v5 API endpoint
    const msg91Url = `https://control.msg91.com/api/v5/otp?template_id=${MSG91_TEMPLATE_ID}&mobile=${cleanPhone}&otp=${otp}`;

    const response = await fetch(msg91Url, {
      method: "POST",
      headers: {
        "authkey": MSG91_AUTHKEY,
        "Content-Type": "application/json",
      },
      // FIX: MSG91 crashes with a 400 error if you claim it's JSON but provide no body!
      body: JSON.stringify({}),
    });

    if (!response.ok) {
      const errorData = await response.text();
      // FIX: Print the exact MSG91 error to Supabase logs for easy debugging
      console.error("MSG91 API error details:", errorData);
      throw new Error(`MSG91 API error: ${errorData}`);
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });

  } catch (err) {
    console.error("Hook Error:", err);
    return new Response(JSON.stringify({ error: err instanceof Error ? err.message : "Unknown error" }), {
      headers: { "Content-Type": "application/json" },
      status: 500
    });
  }
});