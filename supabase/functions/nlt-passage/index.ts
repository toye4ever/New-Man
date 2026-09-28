import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const apiKey = Deno.env.get("NLT_API_KEY");
    if (!apiKey) {
      return json({ error: "NLT_API_KEY is not configured on the server." }, 500);
    }

    const body = await request.json();
    const reference = String(body.reference ?? "").trim();
    if (!reference || reference.length > 160) {
      return json({ error: "A valid Bible reference is required." }, 400);
    }

    const endpoint = new URL("https://api.nlt.to/api/passages");
    endpoint.searchParams.set("ref", reference);
    endpoint.searchParams.set("version", "NLT");
    endpoint.searchParams.set("key", apiKey);

    const response = await fetch(endpoint);
    const html = await response.text();
    if (!response.ok) {
      return json({ error: "The NLT provider rejected the passage request." }, response.status);
    }

    const text = htmlToPlainText(html);
    return json({ reference, text, html });
  } catch (error) {
    console.error(error);
    return json({ error: "The NLT passage could not be retrieved." }, 500);
  }
});

function json(payload: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function htmlToPlainText(html: string) {
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<\/p>/gi, "\n\n")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+\n/g, "\n")
    .replace(/\n\s+/g, "\n")
    .replace(/[ \t]+/g, " ")
    .trim();
}
