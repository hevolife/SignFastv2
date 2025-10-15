/*
  # Complete SignFast Database Schema
  
  This migration creates the entire database schema from scratch for SignFast application.
  
  ## Tables Created
  
  1. **user_profiles** - Extended user information
  2. **forms** - Form definitions and configurations
  3. **form_responses** - User submissions to forms
  4. **pdf_templates** - PDF template definitions
  5. **pdf_storage** - Generated PDF documents
  6. **secret_codes** - Promotional and access codes
  7. **user_secret_codes** - User code activations
  8. **stripe_customers** - Stripe customer records
  9. **stripe_subscriptions** - Subscription management
  10. **affiliate_programs** - Affiliate program data
  11. **affiliate_referrals** - Referral tracking
  12. **support_tickets** - Customer support tickets
  13. **support_messages** - Support ticket messages
  
  ## Security
  - Row Level Security (RLS) enabled on all tables
  - Policies for user data access
  - Admin role checks via is_super_admin() function
  
  ## Performance
  - Indexes on frequently queried columns
  - Triggers for automatic timestamp updates
*/

-- =====================================================
-- EXTENSIONS
-- =====================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- CUSTOM TYPES
-- =====================================================

-- Ticket status enum
DO $$ BEGIN
  CREATE TYPE ticket_status AS ENUM ('open', 'in_progress', 'resolved', 'closed');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Ticket priority enum
DO $$ BEGIN
  CREATE TYPE ticket_priority AS ENUM ('low', 'medium', 'high', 'urgent');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to check if user is super admin
CREATE OR REPLACE FUNCTION is_super_admin()
RETURNS boolean AS $$
BEGIN
  RETURN (
    SELECT COALESCE(
      (SELECT raw_user_meta_data->>'is_super_admin' = 'true'
       FROM auth.users
       WHERE id = auth.uid()),
      false
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TABLE: user_profiles
-- =====================================================

CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name text,
  last_name text,
  company_name text,
  address text,
  siret text,
  logo_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id)
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Super admins can view all profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (is_super_admin());

CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);

CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- TABLE: forms
-- =====================================================

CREATE TABLE IF NOT EXISTS forms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text DEFAULT '',
  fields jsonb DEFAULT '[]'::jsonb,
  settings jsonb DEFAULT '{
    "allowMultiple": true,
    "requireAuth": false,
    "collectEmail": true,
    "generatePdf": false,
    "emailPdf": false,
    "savePdfToServer": false
  }'::jsonb,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  is_published boolean DEFAULT false,
  password text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE forms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own forms"
  ON forms FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own forms"
  ON forms FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own forms"
  ON forms FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own forms"
  ON forms FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Super admins can view all forms"
  ON forms FOR SELECT
  TO authenticated
  USING (is_super_admin());

CREATE POLICY "Public can view published forms"
  ON forms FOR SELECT
  TO anon
  USING (is_published = true);

CREATE INDEX IF NOT EXISTS idx_forms_user_id ON forms(user_id);
CREATE INDEX IF NOT EXISTS idx_forms_is_published ON forms(is_published);
CREATE INDEX IF NOT EXISTS idx_forms_created_at ON forms(created_at DESC);

CREATE TRIGGER update_forms_updated_at
  BEFORE UPDATE ON forms
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- TABLE: form_responses (renamed from responses)
-- =====================================================

CREATE TABLE IF NOT EXISTS form_responses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  form_id uuid NOT NULL REFERENCES forms(id) ON DELETE CASCADE,
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  ip_address text,
  user_agent text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE form_responses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Form owners can view responses"
  ON form_responses FOR SELECT
  TO authenticated
  USING (
    form_id IN (
      SELECT id FROM forms WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Super admins can view all responses"
  ON form_responses FOR SELECT
  TO authenticated
  USING (is_super_admin());

CREATE POLICY "Anyone can submit responses to published forms"
  ON form_responses FOR INSERT
  TO anon, authenticated
  WITH CHECK (
    form_id IN (
      SELECT id FROM forms WHERE is_published = true
    )
  );

CREATE INDEX IF NOT EXISTS idx_form_responses_form_id ON form_responses(form_id);
CREATE INDEX IF NOT EXISTS idx_form_responses_created_at ON form_responses(created_at DESC);

-- =====================================================
-- TABLE: pdf_templates
-- =====================================================

CREATE TABLE IF NOT EXISTS pdf_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text DEFAULT '',
  pdf_content text NOT NULL,
  fields jsonb DEFAULT '[]'::jsonb,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  is_public boolean DEFAULT false,
  linked_form_id uuid REFERENCES forms(id) ON DELETE SET NULL,
  pages integer DEFAULT 1,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE pdf_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own templates"
  ON pdf_templates FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR is_public = true);

CREATE POLICY "Users can create own templates"
  ON pdf_templates FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own templates"
  ON pdf_templates FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own templates"
  ON pdf_templates FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Super admins can view all templates"
  ON pdf_templates FOR SELECT
  TO authenticated
  USING (is_super_admin());

CREATE INDEX IF NOT EXISTS idx_pdf_templates_user_id ON pdf_templates(user_id);
CREATE INDEX IF NOT EXISTS idx_pdf_templates_is_public ON pdf_templates(is_public);
CREATE INDEX IF NOT EXISTS idx_pdf_templates_linked_form_id ON pdf_templates(linked_form_id);

CREATE TRIGGER update_pdf_templates_updated_at
  BEFORE UPDATE ON pdf_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- TABLE: pdf_storage
-- =====================================================

CREATE TABLE IF NOT EXISTS pdf_storage (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  file_name text NOT NULL,
  response_id uuid REFERENCES form_responses(id) ON DELETE SET NULL,
  template_name text DEFAULT '',
  form_title text NOT NULL,
  form_data jsonb DEFAULT '{}'::jsonb,
  pdf_content text NOT NULL,
  file_size integer DEFAULT 0,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE pdf_storage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own PDFs"
  ON pdf_storage FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own PDFs"
  ON pdf_storage FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own PDFs"
  ON pdf_storage FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Super admins can view all PDFs"
  ON pdf_storage FOR SELECT
  TO authenticated
  USING (is_super_admin());

CREATE INDEX IF NOT EXISTS idx_pdf_storage_user_id ON pdf_storage(user_id);
CREATE INDEX IF NOT EXISTS idx_pdf_storage_response_id ON pdf_storage(response_id);
CREATE INDEX IF NOT EXISTS idx_pdf_storage_created_at ON pdf_storage(created_at DESC);

CREATE TRIGGER update_pdf_storage_updated_at
  BEFORE UPDATE ON pdf_storage
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- TABLE: secret_codes
-- =====================================================

CREATE TABLE IF NOT EXISTS secret_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  type text NOT NULL,
  description text DEFAULT '',
  max_uses integer,
  current_uses integer DEFAULT 0,
  expires_at timestamptz,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE secret_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Super admins can manage secret codes"
  ON secret_codes FOR ALL
  TO authenticated
  USING (is_super_admin())
  WITH CHECK (is_super_admin());

CREATE POLICY "Users can view active codes"
  ON secret_codes FOR SELECT
  TO authenticated
  USING (is_active = true AND (expires_at IS NULL OR expires_at > now()));

CREATE INDEX IF NOT EXISTS idx_secret_codes_code ON secret_codes(code);
CREATE INDEX IF NOT EXISTS idx_secret_codes_is_active ON secret_codes(is_active);
CREATE INDEX IF NOT EXISTS idx_secret_codes_expires_at ON secret_codes(expires_at);

CREATE TRIGGER update_secret_codes_updated_at
  BEFORE UPDATE ON secret_codes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- TABLE: user_secret_codes
-- =====================================================

CREATE TABLE IF NOT EXISTS user_secret_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  code_id uuid NOT NULL REFERENCES secret_codes(id) ON DELETE CASCADE,
  activated_at timestamptz DEFAULT now(),
  expires_at timestamptz,
  UNIQUE(user_id, code_id)
);

ALTER TABLE user_secret_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own activated codes"
  ON user_secret_codes FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can activate codes"
  ON user_secret_codes FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Super admins can view all activated codes"
  ON user_secret_codes FOR SELECT
  TO authenticated
  USING (is_super_admin());

CREATE INDEX IF NOT EXISTS idx_user_secret_codes_user_id ON user_secret_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_user_secret_codes_code_id ON user_secret_codes(code_id);

-- =====================================================
-- TABLE: stripe_customers
-- =====================================================

CREATE TABLE IF NOT EXISTS stripe_customers (
  id serial PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  customer_id text NOT NULL UNIQUE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE(user_id)
);

ALTER TABLE stripe_customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own stripe customer"
  ON stripe_customers FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Super admins can view all stripe customers"
  ON stripe_customers FOR SELECT
  TO authenticated
  USING (is_super_admin());

CREATE INDEX IF NOT EXISTS idx_stripe_customers_user_id ON stripe_customers(user_id);
CREATE INDEX IF NOT EXISTS idx_stripe_customers_customer_id ON stripe_customers(customer_id);

CREATE TRIGGER update_stripe_customers_updated_at
  BEFORE UPDATE ON stripe_customers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- TABLE: stripe_subscriptions
-- =====================================================

CREATE TABLE IF NOT EXISTS stripe_subscriptions (
  id serial PRIMARY KEY,
  customer_id text NOT NULL REFERENCES stripe_customers(customer_id) ON DELETE CASCADE,
  subscription_id text UNIQUE,
  price_id text,
  current_period_start bigint,
  current_period_end bigint,
  cancel_at_period_end boolean DEFAULT false,
  payment_method_brand text,
  payment_method_last4 text,
  status text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE stripe_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscriptions"
  ON stripe_subscriptions FOR SELECT
  TO authenticated
  USING (
    customer_id IN (
      SELECT customer_id FROM stripe_customers WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Super admins can view all subscriptions"
  ON stripe_subscriptions FOR SELECT
  TO authenticated
  USING (is_super_admin());

CREATE INDEX IF NOT EXISTS idx_stripe_subscriptions_customer_id ON stripe_subscriptions(customer_id);
CREATE INDEX IF NOT EXISTS idx_stripe_subscriptions_subscription_id ON stripe_subscriptions(subscription_id);
CREATE INDEX IF NOT EXISTS idx_stripe_subscriptions_status ON stripe_subscriptions(status);

CREATE TRIGGER update_stripe_subscriptions_updated_at
  BEFORE UPDATE ON stripe_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- TABLE: affiliate_programs
-- =====================================================

CREATE TABLE IF NOT EXISTS affiliate_programs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  affiliate_code text NOT NULL UNIQUE,
  commission_rate numeric(5,2) DEFAULT 10.00,
  total_referrals integer DEFAULT 0,
  total_earnings numeric(10,2) DEFAULT 0.00,
  monthly_earnings numeric(10,2) DEFAULT 0.00,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id)
);

ALTER TABLE affiliate_programs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own affiliate program"
  ON affiliate_programs FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own affiliate program"
  ON affiliate_programs FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own affiliate program"
  ON affiliate_programs FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Super admins can view all affiliate programs"
  ON affiliate_programs FOR SELECT
  TO authenticated
  USING (is_super_admin());

CREATE POLICY "Public can view affiliate codes"
  ON affiliate_programs FOR SELECT
  TO anon
  USING (is_active = true);

CREATE INDEX IF NOT EXISTS idx_affiliate_programs_user_id ON affiliate_programs(user_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_programs_affiliate_code ON affiliate_programs(affiliate_code);
CREATE INDEX IF NOT EXISTS idx_affiliate_programs_is_active ON affiliate_programs(is_active);

CREATE TRIGGER update_affiliate_programs_updated_at
  BEFORE UPDATE ON affiliate_programs
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- TABLE: affiliate_referrals
-- =====================================================

CREATE TABLE IF NOT EXISTS affiliate_referrals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  affiliate_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  referred_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subscription_id text REFERENCES stripe_subscriptions(subscription_id) ON DELETE SET NULL,
  commission_amount numeric(10,2) DEFAULT 0.00,
  commission_rate numeric(5,2) DEFAULT 10.00,
  status text DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  paid_at timestamptz,
  CONSTRAINT valid_status CHECK (status IN ('pending', 'confirmed', 'paid', 'cancelled'))
);

ALTER TABLE affiliate_referrals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Affiliates can view own referrals"
  ON affiliate_referrals FOR SELECT
  TO authenticated
  USING (auth.uid() = affiliate_user_id);

CREATE POLICY "Super admins can manage all referrals"
  ON affiliate_referrals FOR ALL
  TO authenticated
  USING (is_super_admin())
  WITH CHECK (is_super_admin());

CREATE INDEX IF NOT EXISTS idx_affiliate_referrals_affiliate_user_id ON affiliate_referrals(affiliate_user_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_referrals_referred_user_id ON affiliate_referrals(referred_user_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_referrals_subscription_id ON affiliate_referrals(subscription_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_referrals_status ON affiliate_referrals(status);

-- =====================================================
-- TABLE: support_tickets
-- =====================================================

CREATE TABLE IF NOT EXISTS support_tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subject text NOT NULL,
  status ticket_status DEFAULT 'open' NOT NULL,
  priority ticket_priority DEFAULT 'medium' NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own tickets"
  ON support_tickets FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Super admins can view all tickets"
  ON support_tickets FOR SELECT
  TO authenticated
  USING (is_super_admin());

CREATE POLICY "Users can create own tickets"
  ON support_tickets FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Super admins can update all tickets"
  ON support_tickets FOR UPDATE
  TO authenticated
  USING (is_super_admin())
  WITH CHECK (is_super_admin());

CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_created_at ON support_tickets(created_at DESC);

CREATE TRIGGER update_support_tickets_updated_at
  BEFORE UPDATE ON support_tickets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- TABLE: support_messages
-- =====================================================

CREATE TABLE IF NOT EXISTS support_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id uuid NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message text NOT NULL,
  is_admin_reply boolean DEFAULT false NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE support_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view messages on own tickets"
  ON support_messages FOR SELECT
  TO authenticated
  USING (
    ticket_id IN (
      SELECT id FROM support_tickets WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Super admins can view all messages"
  ON support_messages FOR SELECT
  TO authenticated
  USING (is_super_admin());

CREATE POLICY "Users can send messages on own tickets"
  ON support_messages FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id AND
    ticket_id IN (
      SELECT id FROM support_tickets WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Super admins can send messages on any ticket"
  ON support_messages FOR INSERT
  TO authenticated
  WITH CHECK (is_super_admin());

CREATE INDEX IF NOT EXISTS idx_support_messages_ticket_id ON support_messages(ticket_id);
CREATE INDEX IF NOT EXISTS idx_support_messages_created_at ON support_messages(created_at DESC);

-- =====================================================
-- STORAGE BUCKETS
-- =====================================================

-- Create storage bucket for user logos
INSERT INTO storage.buckets (id, name, public)
VALUES ('user-logos', 'user-logos', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage bucket for PDF documents
INSERT INTO storage.buckets (id, name, public)
VALUES ('pdf-documents', 'pdf-documents', false)
ON CONFLICT (id) DO NOTHING;

-- Create storage bucket for form attachments
INSERT INTO storage.buckets (id, name, public)
VALUES ('form-attachments', 'form-attachments', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for user-logos
CREATE POLICY "Users can upload own logo"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'user-logos' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can update own logo"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'user-logos' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can delete own logo"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'user-logos' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Anyone can view logos"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'user-logos');

-- Storage policies for pdf-documents
CREATE POLICY "Users can upload own PDFs"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'pdf-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can view own PDFs"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'pdf-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can delete own PDFs"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'pdf-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Storage policies for form-attachments
CREATE POLICY "Users can upload form attachments"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'form-attachments');

CREATE POLICY "Users can view form attachments"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'form-attachments');

-- =====================================================
-- INITIAL DATA
-- =====================================================

-- Insert default secret codes (optional)
INSERT INTO secret_codes (code, type, description, max_uses, is_active)
VALUES 
  ('WELCOME2024', 'trial', 'Code de bienvenue pour 30 jours gratuits', 100, true),
  ('PREMIUM50', 'discount', 'Réduction de 50% sur le premier mois', 50, true)
ON CONFLICT (code) DO NOTHING;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '✅ SignFast database schema created successfully!';
  RAISE NOTICE '📊 Tables created: 13';
  RAISE NOTICE '🔒 RLS policies: Enabled on all tables';
  RAISE NOTICE '📦 Storage buckets: 3 (user-logos, pdf-documents, form-attachments)';
  RAISE NOTICE '🎯 Ready for production use!';
END $$;
