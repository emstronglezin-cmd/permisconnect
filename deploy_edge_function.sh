#!/bin/bash
# ============================================================
# PermisConnect — Déploiement Edge Function register-user
# ============================================================
# Ce script déploie l'Edge Function qui permet l'inscription
# SANS confirmation email (via admin.createUser + email_confirm:true)
#
# PRÉREQUIS :
#   1. Avoir le personal access token Supabase :
#      → https://supabase.com/dashboard/account/tokens
#      → "Generate new token" → copier le token
#
# UTILISATION :
#   chmod +x deploy_edge_function.sh
#   SUPABASE_ACCESS_TOKEN="sbp_xxxxxxxxxxxx" ./deploy_edge_function.sh
# ============================================================

set -e

PROJECT_REF="hruisploxlmhigbsnzbn"
FUNCTION_NAME="register-user"

# Vérification du token
if [ -z "$SUPABASE_ACCESS_TOKEN" ]; then
  echo ""
  echo "❌ ERREUR: SUPABASE_ACCESS_TOKEN manquant"
  echo ""
  echo "Comment obtenir votre token :"
  echo "  1. Allez sur https://supabase.com/dashboard/account/tokens"
  echo "  2. Cliquez 'Generate new token'"
  echo "  3. Copiez le token (commence par sbp_)"
  echo ""
  echo "Puis lancez:"
  echo "  SUPABASE_ACCESS_TOKEN='sbp_xxx' ./deploy_edge_function.sh"
  echo ""
  exit 1
fi

echo "🚀 Déploiement Edge Function '$FUNCTION_NAME' sur projet $PROJECT_REF..."

# Installer supabase CLI si nécessaire
if ! command -v supabase &> /dev/null; then
  echo "📦 Installation Supabase CLI..."
  curl -fsSL https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz \
    | tar xz -C /tmp/
  export PATH="/tmp:$PATH"
fi

# Déployer
SUPABASE_ACCESS_TOKEN="$SUPABASE_ACCESS_TOKEN" supabase functions deploy "$FUNCTION_NAME" \
  --project-ref "$PROJECT_REF" \
  --no-verify-jwt

echo ""
echo "✅ Edge Function '$FUNCTION_NAME' déployée avec succès !"
echo ""
echo "📱 L'inscription dans PermisConnect fonctionne maintenant SANS confirmation email."
echo ""
echo "Test rapide :"
echo "  curl -X POST 'https://$PROJECT_REF.supabase.co/functions/v1/$FUNCTION_NAME' \\"
echo "    -H 'apikey: \$ANON_KEY' \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"email\":\"test@example.com\",\"password\":\"Test12345!\",\"full_name\":\"Test User\"}'"
