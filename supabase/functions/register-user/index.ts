/**
 * PermisConnect — Edge Function: register-user
 * Crée un compte utilisateur PRÉ-CONFIRMÉ sans attendre la validation email.
 * Utilise la service_role key côté serveur pour bypass la confirmation email.
 * 
 * Variable d'environnement requise dans Supabase:
 *   SUPABASE_SERVICE_ROLE_KEY=eyJ...
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
    const { email, password, full_name, phone } = await req.json();

    // Validation basique
    if (!email || !password || !full_name) {
      return new Response(
        JSON.stringify({ error: "email, password et full_name sont requis" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (password.length < 8) {
      return new Response(
        JSON.stringify({ error: "Le mot de passe doit avoir au moins 8 caractères" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Créer le client admin avec service_role key
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    // Créer l'utilisateur PRÉ-CONFIRMÉ (email_confirm: true bypass la confirmation)
    const { data: userData, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email: email.trim().toLowerCase(),
      password: password,
      email_confirm: true, // ← CLÉ: bypass la confirmation email
      user_metadata: {
        full_name: full_name.trim(),
        phone: phone?.trim() || null,
      },
    });

    if (createError) {
      console.error("Erreur création user:", createError.message);
      
      // Email déjà utilisé
      if (createError.message.includes("already registered") || 
          createError.message.includes("already been registered") ||
          createError.message.includes("duplicate")) {
        return new Response(
          JSON.stringify({ error: "email_already_used", message: "Cet email est déjà utilisé." }),
          { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({ error: createError.message }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Connexion immédiate avec le compte créé
    const supabaseAnon = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    );

    const { data: signInData, error: signInError } = await supabaseAnon.auth.signInWithPassword({
      email: email.trim().toLowerCase(),
      password: password,
    });

    if (signInError) {
      console.error("Erreur signin après création:", signInError.message);
      // Le compte est créé mais la session a échoué — retourner quand même succès
      return new Response(
        JSON.stringify({ 
          success: true, 
          user_id: userData.user?.id,
          session: null,
          message: "Compte créé. Connectez-vous."
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        user_id: userData.user?.id,
        access_token: signInData.session?.access_token,
        refresh_token: signInData.session?.refresh_token,
        expires_at: signInData.session?.expires_at,
        user: {
          id: signInData.user?.id,
          email: signInData.user?.email,
        }
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err) {
    console.error("Erreur inattendue:", err);
    return new Response(
      JSON.stringify({ error: "Erreur serveur inattendue" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
