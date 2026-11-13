/* Retag Chat shared Supabase Auth client.
 * Safe to load after @supabase/supabase-js v2.
 * Uses only the public publishable key; never put service_role keys here.
 * This file does not read or write profile/message rows.
 */
(function (global) {
  "use strict";

  const SUPABASE_URL = "https://xyozmkrwapfhozdfsasg.supabase.co";
  const SUPABASE_PUBLISHABLE_KEY = "sb_publishable_E-vBSfLso7SYBmPhAkt-aA_lMgBuzKr";

  if (!global.supabase || typeof global.supabase.createClient !== "function") {
    throw new Error("Supabase JS v2 must be loaded before retag-auth.js.");
  }

  const client = global.supabase.createClient(
    SUPABASE_URL,
    SUPABASE_PUBLISHABLE_KEY,
    {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true
      }
    }
  );

  const api = Object.freeze({
    client,
    signUp(email, password, displayName) {
      return client.auth.signUp({
        email: String(email || "").trim(),
        password,
        options: {
          data: { display_name: String(displayName || "").trim() }
        }
      });
    },
    signIn(email, password) {
      return client.auth.signInWithPassword({
        email: String(email || "").trim(),
        password
      });
    },
    signOut() {
      return client.auth.signOut();
    },
    getSession() {
      return client.auth.getSession();
    },
    onAuthStateChange(callback) {
      if (typeof callback !== "function") {
        throw new TypeError("onAuthStateChange expects a callback.");
      }
      return client.auth.onAuthStateChange(callback);
    }
  });

  Object.defineProperty(global, "RetagAuth", {
    value: api,
    writable: false,
    configurable: false,
    enumerable: true
  });
})(window);
