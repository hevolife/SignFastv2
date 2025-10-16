#!/bin/bash

echo "🔍 DIAGNOSTIC RLS - form_responses"
echo "=================================="
echo ""

cd /var/www/SignFastv2

echo "1️⃣ Vérification de la table form_responses..."
npx supabase db remote exec "
SELECT 
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'form_responses';
"

echo ""
echo "2️⃣ Liste des policies sur form_responses..."
npx supabase db remote exec "
SELECT 
  policyname,
  cmd as command,
  roles,
  qual as using_expression,
  with_check as with_check_expression
FROM pg_policies 
WHERE tablename = 'form_responses';
"

echo ""
echo "3️⃣ Permissions GRANT sur form_responses..."
npx supabase db remote exec "
SELECT 
  grantee,
  privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public'
AND table_name = 'form_responses'
AND grantee IN ('anon', 'authenticated', 'public');
"

echo ""
echo "4️⃣ Test d'accès anonyme direct..."
curl -X POST "https://signfast.hevolife.fr/rest/v1/form_responses" \
  -H "apikey: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc1OTA5MTIyMCwiZXhwIjo0OTE0NzY0ODIwLCJyb2xlIjoiYW5vbiJ9.4BQ0CUqu4P-4rkgEsI9TtH2Oby81Ry81qh0a6353drY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"form_id":"00000000-0000-0000-0000-000000000000","data":{},"ip_address":"test","user_agent":"test"}' \
  -v 2>&1 | grep -E "(HTTP|401|403|message)"

echo ""
echo "5️⃣ Vérification d'un formulaire publié..."
npx supabase db remote exec "
SELECT 
  id,
  title,
  is_published,
  user_id
FROM forms 
WHERE is_published = true 
LIMIT 1;
"

echo ""
echo "✅ Diagnostic terminé"
