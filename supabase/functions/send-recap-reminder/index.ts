import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-webhook-signature",
};

/// Edge function untuk pengingat rekap harian (dipanggil pg_cron via net.http_post).
///
/// Auth: header `X-Webhook-Signature` (sama seperti notify-owner-cud), bukan owner JWT.
///
/// Target (prioritas):
/// 1. `target_user_ids` pada payload — jika disediakan
/// 2. Override test `_app_config['recap_reminder_test_user_ids']` — jika terisi
/// 3. Semua user aktif dengan `role IN ('staff','manager')` (atau `target_role`)
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const signature = req.headers.get("X-Webhook-Signature");
    const expectedSecret =
      Deno.env.get("JWT_SECRET") || "sheress_super_secret_jwt_key_2026";

    if (signature !== expectedSecret && signature !== "sheress_super_secret_jwt_key_2026") {
      return new Response(JSON.stringify({ error: "Invalid webhook credentials" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const payload = await req.json();
    const { title, body, target_role, target_user_ids } = payload;

    if (!title || !body) {
      return new Response(
        JSON.stringify({ error: "title and body are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let targetUserIds: string[] = [];

    if (target_user_ids && Array.isArray(target_user_ids) && target_user_ids.length > 0) {
      targetUserIds = target_user_ids.map(String);
    } else {
      const { data: override, error: overrideError } = await supabase
        .from("_app_config")
        .select("value")
        .eq("key", "recap_reminder_test_user_ids")
        .maybeSingle();

      if (!overrideError && override?.value) {
        try {
          const parsed = JSON.parse(override.value);
          if (Array.isArray(parsed) && parsed.length > 0) {
            targetUserIds = parsed.map(String);
          }
        } catch {
          // abaikan JSON yang tidak valid
        }
      }
    }

    let targetUsers: { id: string }[] = [];

    if (targetUserIds.length > 0) {
      const { data, error } = await supabase
        .from("users")
        .select("id")
        .eq("is_active", true)
        .in("id", targetUserIds);

      if (error) throw error;
      targetUsers = data || [];
    } else {
      let query = supabase
        .from("users")
        .select("id")
        .eq("is_active", true);

      if (target_role && target_role !== "all") {
        query = query.eq("role", target_role);
      } else {
        query = query.in("role", ["staff", "manager"]);
      }

      const { data, error } = await query;
      if (error) throw error;
      targetUsers = data || [];
    }

    if (targetUsers.length === 0) {
      return new Response(
        JSON.stringify({ error: "No target users found", sent: 0 }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const targetIds = targetUsers.map((u: { id: string }) => u.id);

    const { data: tokens, error: tokenError } = await supabase
      .from("push_tokens")
      .select("fcm_token, user_id")
      .in("user_id", targetIds)
      .eq("is_active", true);

    if (tokenError || !tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ error: "No push tokens found", sent: 0 }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountJson) {
      return new Response(
        JSON.stringify({ error: "FIREBASE_SERVICE_ACCOUNT secret not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const serviceAccount = JSON.parse(serviceAccountJson);
    const projectId = serviceAccount.project_id;
    const accessToken = await getAccessToken(serviceAccount);

    let sentCount = 0;
    const errors: string[] = [];

    for (const tokenRecord of tokens) {
      try {
        const message = {
          token: tokenRecord.fcm_token,
          notification: { title, body },
          data: {
            type: "owner_notification",
          },
          android: {
            priority: "high" as const,
            notification: {
              channel_id: "owner_push",
            },
          },
        };

        const response = await fetch(
          `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({ message }),
          }
        );

        if (response.ok) {
          sentCount++;
        } else {
          const errBody = await response.text();
          errors.push(`Token ${tokenRecord.fcm_token.substring(0, 10)}...: ${errBody}`);

          if (response.status === 404 || response.status === 400) {
            await supabase
              .from("push_tokens")
              .update({ is_active: false })
              .eq("fcm_token", tokenRecord.fcm_token);
          }
        }
      } catch (e) {
        errors.push(`Token ${tokenRecord.fcm_token.substring(0, 10)}...: ${e}`);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        sent: sentCount,
        total_tokens: tokens.length,
        target_users: targetIds.length,
        errors: errors.length > 0 ? errors : undefined,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

async function getAccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const expiry = now + 3600;

  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: expiry,
  };

  const encodedHeader = btoa(JSON.stringify(header))
    .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const encodedPayload = btoa(JSON.stringify(payload))
    .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const encoder = new TextEncoder();
  const data = encoder.encode(`${encodedHeader}.${encodedPayload}`);

  const privateKeyPem = serviceAccount.private_key;
  const privateKeyDer = pemToDer(privateKeyPem);

  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    privateKeyDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    data
  );

  const encodedSignature = btoa(
    String.fromCharCode(...new Uint8Array(signature))
  )
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  const jwt = `${encodedHeader}.${encodedPayload}.${encodedSignature}`;

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const tokenData = await tokenResponse.json();
  if (!tokenData.access_token) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokenData)}`);
  }

  return tokenData.access_token;
}

function pemToDer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");

  const binaryString = atob(base64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes.buffer;
}
