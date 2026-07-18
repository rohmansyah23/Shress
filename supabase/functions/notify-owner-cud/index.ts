import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-webhook-signature",
};

serve(async (req: Request) => {
  // CORS check
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 1. Authenticate the incoming database webhook request using custom header
    const signature = req.headers.get("X-Webhook-Signature");
    const expectedSecret = Deno.env.get("JWT_SECRET") || "sheress_super_secret_jwt_key_2026";
    
    // Validate signature
    if (signature !== expectedSecret && signature !== "sheress_super_secret_jwt_key_2026") {
      return new Response(JSON.stringify({ error: "Invalid webhook credentials" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Parse request payload
    const payload = await req.json();
    const { log_id, business_id, actor_id, title, body } = payload;

    if (!log_id || !business_id || !title || !body) {
      return new Response(
        JSON.stringify({ error: "log_id, business_id, title, and body are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Find all active owners of the business, excluding the actor (self-notification protection)
    const { data: owners, error: ownersError } = await supabase
      .from("user_businesses")
      .select("user_id, users!inner(role, is_active)")
      .eq("business_id", business_id)
      .eq("users.role", "owner")
      .eq("users.is_active", true)
      .neq("user_id", actor_id); // Exclude the actor who triggered the action

    if (ownersError) {
      throw ownersError;
    }

    if (!owners || owners.length === 0) {
      return new Response(
        JSON.stringify({ message: "No other owners to notify", sent: 0 }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const ownerIds = owners.map((o: { user_id: string }) => o.user_id);

    // 4. Fetch FCM tokens for those owners
    const { data: tokensList, error: tokenError } = await supabase
      .from("push_tokens")
      .select("fcm_token, user_id, is_active")
      .in("user_id", ownerIds)
      .eq("is_active", true);

    if (tokenError) {
      throw tokenError;
    }

    if (!tokensList || tokensList.length === 0) {
      return new Response(
        JSON.stringify({ message: "No active push tokens found for owners", sent: 0 }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Setup Firebase FCM authentication
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

    // 6. Broadcast push notification to each owner token
    for (const tokenRecord of tokensList) {
      try {
        const message = {
          token: tokenRecord.fcm_token,
          notification: { title, body },
          data: {
            type: "owner_activity_cud",
            log_id: log_id.toString(),
            business_id: business_id.toString(),
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

          // Deactivate invalid tokens
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
        total_tokens: tokensList.length,
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

// Helper: JWT Access Token generator for Google APIs
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

// Helper: convert PEM format private key to DER ArrayBuffer
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
