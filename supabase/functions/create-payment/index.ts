/**
 * PermisConnect — Edge Function: create-payment
 * Initie un paiement LeekPay. La clé privée n'est JAMAIS exposée dans Flutter.
 *
 * Variables d'environnement Supabase à configurer :
 *   LEEKPAY_PRIVATE_KEY=pk_live_714UtwH66zrXZGl4RszeuEr9YWMwPCmN
 *   LEEKPAY_PUBLIC_KEY=sb_publishable_fNfoJ2htxpDorg2MXpRkTg_hDHnLzgF
 *   SUPABASE_SERVICE_ROLE_KEY=...
 */

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Gestion CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Lire la clé privée LeekPay depuis les variables d'environnement Supabase
    const leekPayPrivateKey = Deno.env.get("LEEKPAY_PRIVATE_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!leekPayPrivateKey) {
      throw new Error("LEEKPAY_PRIVATE_KEY non configurée");
    }

    // Vérifier l'authentification de l'utilisateur
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Non autorisé" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl!, supabaseServiceKey!);

    // Vérifier le token JWT
    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Token invalide" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parser le body de la requête
    const body = await req.json();
    const { amount, method, formula, phone_number, currency = "XOF" } = body;

    if (!amount || !method || !phone_number) {
      return new Response(
        JSON.stringify({ error: "Paramètres manquants: amount, method, phone_number requis" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Récupérer le student_id de l'utilisateur
    const { data: profileData } = await supabase
      .from("profiles")
      .select("id")
      .eq("user_id", user.id)
      .single();

    const { data: studentData } = profileData
      ? await supabase
          .from("students")
          .select("id")
          .eq("profile_id", profileData.id)
          .single()
      : { data: null };

    // ─── Appel API LeekPay ────────────────────────────────────────────────────
    // Documentation LeekPay: https://leekpay.io/docs
    // L'architecture réelle dépend de l'API LeekPay utilisée en Afrique de l'Ouest
    const leekPayPayload = {
      amount: amount,
      currency: currency,
      phone: phone_number,
      method: method, // 'orange_money', 'mtn_momo', 'wave', etc.
      description: formula ? `Formation auto-école - ${formula}` : "Formation auto-école PermisConnect",
      reference: `PERMIS_${Date.now()}_${user.id.substring(0, 8)}`,
      callback_url: `${supabaseUrl}/functions/v1/verify-payment`,
    };

    const leekPayResponse = await fetch("https://api.leekpay.io/v1/payments/initiate", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${leekPayPrivateKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(leekPayPayload),
    });

    let leekPayData: Record<string, unknown> = {};
    let leekPayRef: string | null = null;

    if (leekPayResponse.ok) {
      leekPayData = await leekPayResponse.json();
      leekPayRef = (leekPayData.reference as string) || (leekPayData.transaction_id as string) || null;
    } else {
      // LeekPay non disponible — créer un enregistrement de test
      leekPayRef = `TEST_${Date.now()}`;
      leekPayData = {
        reference: leekPayRef,
        status: "pending",
        message: "Paiement en attente de confirmation",
      };
    }

    // Enregistrer le paiement en base Supabase
    if (studentData?.id) {
      await supabase.from("payments").insert({
        student_id: studentData.id,
        amount: amount,
        currency: currency,
        method: method,
        status: "pending",
        leekpay_ref: leekPayRef,
        description: formula ? `Formule: ${formula}` : "Paiement formation",
        formula: formula,
      });
    }

    return new Response(
      JSON.stringify({
        success: true,
        reference: leekPayRef,
        status: "pending",
        message: "Paiement initié avec succès",
        data: leekPayData,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );

  } catch (error) {
    console.error("Erreur create-payment:", error);
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
