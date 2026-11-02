import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { api, setUnauthorizedHandler, tokenStore } from './api';
import type { User } from './types';

interface AuthResponse { accessToken: string; user: User }

interface AuthCtx {
  user: User | null;
  ready: boolean;
  login: (email: string, password: string) => Promise<void>;
  /** Dipakai setelah daftar gym: respons sudah berisi token. */
  adopt: (res: AuthResponse) => void;
  logout: () => void;
}

const Ctx = createContext<AuthCtx | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [ready, setReady] = useState(false);

  const logout = useCallback(() => {
    tokenStore.clear();
    setUser(null);
  }, []);

  useEffect(() => {
    setUnauthorizedHandler(logout);
    if (!tokenStore.get()) { setReady(true); return; }
    api.get<User>('/auth/me')
      .then((u) => (u.role === 'ADMIN' ? setUser(u) : logout()))
      .catch(() => logout())
      .finally(() => setReady(true));
  }, [logout]);

  const adopt = useCallback((res: AuthResponse) => {
    tokenStore.set(res.accessToken);
    setUser(res.user);
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    const res = await api.post<AuthResponse>('/auth/login', { identifier: email, password });
    if (res.user.role !== 'ADMIN') {
      throw new Error('Akun ini bukan admin gym. Gunakan akun yang dibuat saat mendaftarkan gym.');
    }
    adopt(res);
  }, [adopt]);

  const value = useMemo(() => ({ user, ready, login, adopt, logout }), [user, ready, login, adopt, logout]);
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useAuth() {
  const c = useContext(Ctx);
  if (!c) throw new Error('useAuth harus di dalam AuthProvider');
  return c;
}
