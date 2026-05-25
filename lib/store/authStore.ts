import type { Session } from "@supabase/supabase-js";
import { create } from "zustand";
import { supabase } from "@/lib/supabase/client";

interface AuthState {
  session: Session | null;
  loading: boolean;
  onboardingComplete: boolean;
  initialize: () => Promise<void>;
  signInWithEmail: (email: string, password: string) => Promise<void>;
  signUpWithEmail: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  completeOnboarding: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  session: null,
  loading: true,
  onboardingComplete: false,
  initialize: async () => {
    const { data } = await supabase.auth.getSession();
    set({ session: data.session, loading: false });
    supabase.auth.onAuthStateChange((_event, session) => set({ session }));
  },
  signInWithEmail: async (email, password) => {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;
    set({ session: data.session });
  },
  signUpWithEmail: async (email, password) => {
    const { data, error } = await supabase.auth.signUp({ email, password });
    if (error) throw error;
    set({ session: data.session });
  },
  signOut: async () => {
    await supabase.auth.signOut();
    set({ session: null });
  },
  completeOnboarding: () => set({ onboardingComplete: true })
}));
