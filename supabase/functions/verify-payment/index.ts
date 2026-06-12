/**
 * PermisConnect — Edge Function: verify-payment
 * Vérifie le statut d'un paiement LeekPay et met à jour la base de données.
 */

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const leekPayPrivateKey = Deno.env.get("LEEKPAY_PRIVATE_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    const supabase = createClient(supabaseUrl!, supabaseServiceKey!);

    const body = await req.json();
    const { leekpay_ref } = body;

    if (!leekpay_ref) {
      return new Response(
        JSON.stringify({ error: "leekpay_ref requis" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Vérifier le statut auprès de l'API LeekPay
    let paymentStatus = "pending";
    let leekPayData: Record<string, unknown> = {};

    if (leekPayPrivateKey) {
      const leekPayResponse = await fetch(
        `https://api.leekpay.io/v1/payments/${leekpay_ref}`,
        {
          method: "GET",
          headers: {
            "Authorization": `Bearer ${leekPayPrivateKey}`,
          },
        }
      );

      if (leekPayResponse.ok) {
        leekPayData = await leekPayResponse.json();
        paymentStatus = (leekPayData.status as string) || "pending";
      }
    }

    // Mettre à jour le paiement en base
    const updateData: Record<string, unknown> = {
      status: paymentStatus === "success" ? "completed" : paymentStatus,
    };

    if (paymentStatus === "success") {
      updateData.paid_at = new Date().toISOString();
      updateData.transaction_id = leekPayData.transaction_id as string;
    }

    await supabase
      .from("payments")
      .update(updateData)
      .eq("leekpay_ref", leekpay_ref);

    return new Response(
      JSON.stringify({
        success: true,
        status: paymentStatus,
        reference: leekpay_ref,
        data: leekPayData,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );

  } catch (error) {
    console.error("Erreur verify-payment:", error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Erreur interne",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
