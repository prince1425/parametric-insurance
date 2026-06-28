import { createContext, useContext, useMemo, useState } from "react";

import { api, type User } from "../lib/api";

type AuthContextValue = {
  user: User | null;
  token: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
};

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [token, setToken] = useState<string | null>(() => localStorage.getItem("agrishield_token"));
  const [user, setUser] = useState<User | null>(() => {
    const raw = localStorage.getItem("agrishield_user");
    return raw ? (JSON.parse(raw) as User) : null;
  });

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      token,
      async login(email, password) {
        const result = await api.login(email, password);
        localStorage.setItem("agrishield_token", result.access_token);
        localStorage.setItem("agrishield_user", JSON.stringify(result.user));
        setToken(result.access_token);
        setUser(result.user);
      },
      logout() {
        localStorage.removeItem("agrishield_token");
        localStorage.removeItem("agrishield_user");
        setToken(null);
        setUser(null);
      },
    }),
    [token, user],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used inside AuthProvider");
  }
  return context;
}
