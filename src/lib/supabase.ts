import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey || supabaseUrl === 'your-project-url' || supabaseKey === 'your-anon-key' || supabaseUrl.includes('placeholder') || supabaseKey.includes('placeholder')) {
}

// 🔧 Retry avec exponential backoff
const retryFetch = async (url: RequestInfo | URL, options?: RequestInit, maxRetries = 3): Promise<Response> => {
  let lastError: Error | null = null;
  
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      const response = await fetch(url, options);
      
      // Si succès, retourner immédiatement
      if (response.ok || response.status < 500) {
        return response;
      }
      
      // Si erreur serveur, retry
      lastError = new Error(`Server error: ${response.status}`);
      
    } catch (error: any) {
      lastError = error;
      
      // Si c'est une erreur QUIC, attendre avant de retry
      if (error.message?.includes('QUIC') || error.message?.includes('Failed to fetch')) {
        const delay = Math.min(1000 * Math.pow(2, attempt), 5000); // Max 5s
        console.log(`⏳ Retry ${attempt + 1}/${maxRetries} après ${delay}ms...`);
        await new Promise(resolve => setTimeout(resolve, delay));
        continue;
      }
      
      // Autre erreur, throw immédiatement
      throw error;
    }
  }
  
  // Tous les retries ont échoué
  throw lastError || new Error('Max retries reached');
};

// Custom fetch function to handle session expiration and QUIC errors
const customFetch = async (url: RequestInfo | URL, options?: RequestInit) => {
  try {
    // 🚀 Utiliser retry fetch au lieu de fetch direct
    const response = await retryFetch(url, options, 3);
    
    // Handle 500 errors gracefully
    if (response.status === 500) {
      return new Response(JSON.stringify({ data: null, error: null }), {
        status: 200,
        statusText: 'OK (Fallback)',
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Handle other server errors (502, 503, 504)
    if (response.status >= 500) {
      return new Response(JSON.stringify({ data: null, error: null }), {
        status: 200,
        statusText: 'OK (Fallback)',
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Check for session expiration
    if (response.status === 403) {
      try {
        const body = await response.clone().json();
        if (body.code === 'session_not_found') {
          try {
            const { data, error } = await supabase.auth.refreshSession();
            if (error) {
              supabase.auth.signOut();
            }
          } catch (refreshError) {
            supabase.auth.signOut();
          }
        }
      } catch (error) {
        // If we can't parse the response body, ignore
      }
    }
    
    // Handle RPC function not found errors (404 with PGRST202)
    if (!response.ok && response.status === 404) {
      const errorText = await response.text();
      try {
        const errorData = JSON.parse(errorText);
        if (errorData.code === 'PGRST202') {
          return {
            ok: false,
            status: 404,
            json: async () => ({ error: 'RPC function not found', code: 'PGRST202' }),
            text: async () => errorText
          };
        }
      } catch (parseError) {
        // If we can't parse the error, continue with normal error handling
      }
    }
    
    return response;
  } catch (error: any) {
    // 🔥 Si erreur QUIC après tous les retries, retourner données vides
    if (error.message?.includes('QUIC') || error.message?.includes('Failed to fetch')) {
      console.warn('⚠️ QUIC error après retries, retour données vides');
      return new Response(JSON.stringify({ data: [], error: null, count: 0 }), {
        status: 200,
        statusText: 'OK (QUIC Fallback)',
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Re-throw other errors
    throw error;
  }
};

// Check if Supabase is properly configured
const isSupabaseConfigured = () => {
  const url = import.meta.env.VITE_SUPABASE_URL;
  const key = import.meta.env.VITE_SUPABASE_ANON_KEY;
  
  return url && key && 
         url !== 'your-project-url' && 
         key !== 'your-anon-key' && 
         !url.includes('placeholder') && 
         !key.includes('placeholder');
};

// Safe fetch wrapper that handles configuration issues
const safeFetch = async (url: RequestInfo | URL, options?: RequestInit) => {
  if (!isSupabaseConfigured()) {
    return new Response(JSON.stringify({ data: null, error: null }), {
      status: 200,
      statusText: 'OK',
      headers: { 'Content-Type': 'application/json' }
    });
  }
  
  const urlString = url.toString();
  
  // Check if this is a table query request
  if (urlString.includes('/rest/v1/sub_accounts') || urlString.includes('sub_accounts?') ||
      url.includes('/rpc/set_config') ||
      url.includes('users?select=id&email=eq.')) {
    try {
      const response = await customFetch(url, options);
      
      if (response.status === 404 || response.status === 406) {
        const body = await response.clone().text();
        if (body.includes('PGRST205') || body.includes('Could not find the table') || body.includes('sub_accounts')) {
          return new Response(JSON.stringify({ 
            data: null,
            error: { 
              code: 'PGRST205', 
              message: 'Table not found',
              details: 'sub_accounts table does not exist'
            } 
          }), {
            status: 200,
            statusText: 'OK',
            headers: { 'Content-Type': 'application/json' }
          });
        }
      }
      
      return response;
    } catch (error) {
      return new Response(JSON.stringify({ 
        data: null, 
        error: { 
          code: 'NETWORK_ERROR', 
          message: 'Network error',
          details: 'Could not access sub_accounts table'
        } 
      }), {
        status: 200,
        statusText: 'OK',
        headers: { 'Content-Type': 'application/json' }
      });
    }
  }
  
  try {
    return await customFetch(url, options);
  } catch (error) {
    // Re-throw network errors to let Supabase handle them properly
    throw error;
  }
};

export const supabase = createClient(
  supabaseUrl || 'https://placeholder.supabase.co', 
  supabaseKey || 'placeholder-key', 
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
      flowType: 'pkce',
      storage: window.localStorage,
      storageKey: 'sb-auth-token',
    },
    global: {
      fetch: safeFetch,
    },
  }
);

// Export createClient for admin operations
export { createClient };

// Export the configuration check function
export { isSupabaseConfigured };

export type Database = {
  public: {
    Tables: {
      forms: {
        Row: {
          id: string;
          title: string;
          description: string;
          fields: any;
          settings: any;
          user_id: string;
          created_at: string;
          updated_at: string;
          is_published: boolean;
          password: string | null;
        };
        Insert: {
          id?: string;
          title: string;
          description?: string;
          fields: any;
          settings?: any;
          user_id: string;
          created_at?: string;
          updated_at?: string;
          is_published?: boolean;
          password?: string | null;
        };
        Update: {
          id?: string;
          title?: string;
          description?: string;
          fields?: any;
          settings?: any;
          user_id?: string;
          created_at?: string;
          updated_at?: string;
          is_published?: boolean;
          password?: string | null;
        };
      };
      secret_codes: {
        Row: {
          id: string;
          code: string;
          type: string;
          description: string;
          max_uses: number | null;
          current_uses: number;
          expires_at: string | null;
          is_active: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          code: string;
          type: string;
          description?: string;
          max_uses?: number | null;
          current_uses?: number;
          expires_at?: string | null;
          is_active?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          code?: string;
          type?: string;
          description?: string;
          max_uses?: number | null;
          current_uses?: number;
          expires_at?: string | null;
          is_active?: boolean;
          created_at?: string;
          updated_at?: string;
        };
      };
      user_secret_codes: {
        Row: {
          id: string;
          user_id: string;
          code_id: string;
          activated_at: string;
          expires_at: string | null;
        };
        Insert: {
          id?: string;
          user_id: string;
          code_id: string;
          activated_at?: string;
          expires_at?: string | null;
        };
        Update: {
          id?: string;
          user_id?: string;
          code_id?: string;
          activated_at?: string;
          expires_at?: string | null;
        };
      };
      pdf_storage: {
        Row: {
          id: string;
          file_name: string;
          response_id: string | null;
          template_name: string;
          form_title: string;
          form_data: any;
          pdf_content: string;
          file_size: number;
          user_id: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          file_name: string;
          response_id?: string | null;
          template_name?: string;
          form_title: string;
          form_data?: any;
          pdf_content: string;
          file_size?: number;
          user_id: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          file_name?: string;
          response_id?: string | null;
          template_name?: string;
          form_title?: string;
          form_data?: any;
          pdf_content?: string;
          file_size?: number;
          user_id?: string;
          created_at?: string;
          updated_at?: string;
        };
      };
      responses: {
        Row: {
          id: string;
          form_id: string;
          data: any;
          created_at: string;
          ip_address: string | null;
          user_agent: string | null;
        };
        Insert: {
          id?: string;
          form_id: string;
          data: any;
          created_at?: string;
          ip_address?: string | null;
          user_agent?: string | null;
        };
        Update: {
          id?: string;
          form_id?: string;
          data?: any;
          created_at?: string;
          ip_address?: string | null;
          user_agent?: string | null;
        };
      };
      pdf_templates: {
        Row: {
          id: string;
          name: string;
          description: string;
          pdf_content: string;
          fields: any;
          user_id: string;
          is_public: boolean;
          linked_form_id: string | null;
          pages: number;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          description?: string;
          pdf_content: string;
          fields?: any;
          user_id: string;
          is_public?: boolean;
          linked_form_id?: string | null;
          pages?: number;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          name?: string;
          description?: string;
          pdf_content?: string;
          fields?: any;
          user_id?: string;
          is_public?: boolean;
          linked_form_id?: string | null;
          pages?: number;
          created_at?: string;
          updated_at?: string;
        };
      };
      stripe_customers: {
        Row: {
          id: number;
          user_id: string;
          customer_id: string;
          created_at: string;
          updated_at: string;
          deleted_at: string | null;
        };
        Insert: {
          id?: number;
          user_id: string;
          customer_id: string;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
        Update: {
          id?: number;
          user_id?: string;
          customer_id?: string;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
      };
      stripe_subscriptions: {
        Row: {
          id: number;
          customer_id: string;
          subscription_id: string | null;
          price_id: string | null;
          current_period_start: number | null;
          current_period_end: number | null;
          cancel_at_period_end: boolean;
          payment_method_brand: string | null;
          payment_method_last4: string | null;
          status: string;
          created_at: string;
          updated_at: string;
          deleted_at: string | null;
        };
        Insert: {
          id?: number;
          customer_id: string;
          subscription_id?: string | null;
          price_id?: string | null;
          current_period_start?: number | null;
          current_period_end?: number | null;
          cancel_at_period_end?: boolean;
          payment_method_brand?: string | null;
          payment_method_last4?: string | null;
          status: string;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
        Update: {
          id?: number;
          customer_id?: string;
          subscription_id?: string | null;
          price_id?: string | null;
          current_period_start?: number | null;
          current_period_end?: number | null;
          cancel_at_period_end?: boolean;
          payment_method_brand?: string | null;
          payment_method_last4?: string | null;
          status?: string;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
      };
      affiliate_programs: {
        Row: {
          id: string;
          user_id: string;
          affiliate_code: string;
          commission_rate: number;
          total_referrals: number;
          total_earnings: number;
          monthly_earnings: number;
          is_active: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          affiliate_code: string;
          commission_rate?: number;
          total_referrals?: number;
          total_earnings?: number;
          monthly_earnings?: number;
          is_active?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          user_id?: string;
          affiliate_code?: string;
          commission_rate?: number;
          total_referrals?: number;
          total_earnings?: number;
          monthly_earnings?: number;
          is_active?: boolean;
          created_at?: string;
          updated_at?: string;
        };
      };
      affiliate_referrals: {
        Row: {
          id: string;
          affiliate_user_id: string;
          referred_user_id: string;
          subscription_id: string | null;
          commission_amount: number;
          commission_rate: number;
          status: string;
          created_at: string;
          paid_at: string | null;
        };
        Insert: {
          id?: string;
          affiliate_user_id: string;
          referred_user_id: string;
          subscription_id?: string | null;
          commission_amount?: number;
          commission_rate?: number;
          status?: string;
          created_at?: string;
          paid_at?: string | null;
        };
        Update: {
          id?: string;
          affiliate_user_id?: string;
          referred_user_id?: string;
          subscription_id?: string | null;
          commission_amount?: number;
          commission_rate?: number;
          status?: string;
          created_at?: string;
          paid_at?: string | null;
        };
      };
    };
  };
};
