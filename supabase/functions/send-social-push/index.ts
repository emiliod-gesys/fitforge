import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

interface WebhookPayload {
  type: string;
  table: string;
  record: {
    user_id: string;
    actor_id: string;
    message: string;
    type?: string;
  };
}

function base64UrlEncode(data: Uint8Array): string {
  return btoa(String.fromCharCode(...data))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binary = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    binary,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

async function getGoogleAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const encoder = new TextEncoder();
  const headerB64 = base64UrlEncode(encoder.encode(JSON.stringify(header)));
  const claimB64 = base64UrlEncode(encoder.encode(JSON.stringify(claim)));
  const unsigned = `${headerB64}.${claimB64}`;

  const key = await importPrivateKey(sa.private_key);
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    encoder.encode(unsigned),
  );
  const jwt = `${unsigned}.${base64UrlEncode(new Uint8Array(signature))}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!tokenRes.ok) {
    throw new Error(`OAuth token error: ${await tokenRes.text()}`);
  }

  const tokenData = await tokenRes.json();
  return tokenData.access_token as string;
}

async function sendFcm(
  projectId: string,
  accessToken: string,
  deviceToken: string,
  title: string,
  body: string,
  actorId: string,
): Promise<void> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: deviceToken,
          notification: { title, body },
          data: {
            type: "social_workout",
            route: "/social",
            actor_id: actorId,
          },
          android: {
            priority: "HIGH",
            notification: { channel_id: "fitforge_social" },
          },
          apns: {
            payload: { aps: { sound: "default", badge: 1 } },
          },
        },
      }),
    },
  );

  if (!res.ok) {
    const errText = await res.text();
    // Token inválido: el cliente lo renovará en el próximo login.
    if (res.status === 404 || errText.includes("UNREGISTERED")) {
      console.warn("Stale FCM token:", deviceToken.slice(0, 12));
      return;
    }
    throw new Error(`FCM error ${res.status}: ${errText}`);
  }
}

interface PushSecrets {
  firebase_service_account?: string;
  webhook_secret?: string;
}

async function loadPushSecrets(
  supabase: ReturnType<typeof createClient>,
): Promise<{ serviceAccountJson: string; webhookSecret: string | null }> {
  let serviceAccountJson = "";
  let webhookSecret: string | null = null;

  const { data, error } = await supabase.rpc("get_push_notification_secrets");
  if (!error && data) {
    const secrets = data as PushSecrets;
    serviceAccountJson = secrets.firebase_service_account ?? "";
    webhookSecret = secrets.webhook_secret ?? null;
  }

  // Vault primero; variables de entorno solo como respaldo local.
  serviceAccountJson = serviceAccountJson || Deno.env.get("FIREBASE_SERVICE_ACCOUNT") || "";
  webhookSecret = webhookSecret || Deno.env.get("WEBHOOK_SECRET") || null;

  return { serviceAccountJson, webhookSecret };
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    return new Response(
      JSON.stringify({ error: "Missing Supabase env" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);

  let serviceAccountJson: string;
  let webhookSecret: string | null;
  try {
    ({ serviceAccountJson, webhookSecret } = await loadPushSecrets(supabase));
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (webhookSecret) {
    const auth = req.headers.get("Authorization");
    if (auth !== `Bearer ${webhookSecret}`) {
      return new Response("Unauthorized", { status: 401 });
    }
  }

  if (!serviceAccountJson) {
    return new Response(
      JSON.stringify({ error: "Missing FIREBASE_SERVICE_ACCOUNT" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  let payload: WebhookPayload;
  try {
    payload = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (payload.type !== "INSERT" || payload.table !== "social_notifications") {
    return new Response(JSON.stringify({ skipped: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { user_id: userId, message, actor_id: actorId, type: notificationType } = payload.record;
  if (!userId || !message) {
    return new Response(JSON.stringify({ error: "Missing user_id or message" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const bellTypes = new Set([
    "friend_request",
    "feed_comment",
    "feed_reaction",
    "feed_comment_reaction",
    "routine_share",
    "trainer_request",
  ]);

  if (!notificationType || !bellTypes.has(notificationType)) {
    return new Response(JSON.stringify({ skipped: true, reason: "feed_event" }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  const sa = JSON.parse(serviceAccountJson) as ServiceAccount;

  const { data: tokens, error: tokensError } = await supabase
    .from("user_push_tokens")
    .select("token")
    .eq("user_id", userId);

  if (tokensError) {
    return new Response(JSON.stringify({ error: tokensError.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (!tokens?.length) {
    return new Response(JSON.stringify({ sent: 0, reason: "no_tokens" }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  const accessToken = await getGoogleAccessToken(sa);
  const title = "FitForge";
  let sent = 0;

  for (const row of tokens) {
    try {
      await sendFcm(sa.project_id, accessToken, row.token, title, message, actorId ?? "");
      sent++;
    } catch (e) {
      console.error("FCM send failed:", e);
    }
  }

  return new Response(JSON.stringify({ sent }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
