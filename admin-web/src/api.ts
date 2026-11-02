export const API_URL: string =
  (import.meta.env.VITE_API_URL as string | undefined)?.replace(/\/$/, '') ?? 'http://localhost:3000';

/** URL gambar dari server bersifat relatif (/uploads/..); tambahkan alamat server. */
export const imgUrl = (u?: string | null) => (!u ? '' : u.startsWith('http') ? u : API_URL + u);

const TOKEN_KEY = 'gymfit_admin_token';
export const tokenStore = {
  get: () => {
    try { return localStorage.getItem(TOKEN_KEY); } catch { return null; }
  },
  set: (t: string) => {
    try { localStorage.setItem(TOKEN_KEY, t); } catch { /* abaikan */ }
  },
  clear: () => {
    try { localStorage.removeItem(TOKEN_KEY); } catch { /* abaikan */ }
  },
};

export class ApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

let onUnauthorized: (() => void) | null = null;
export const setUnauthorizedHandler = (fn: () => void) => { onUnauthorized = fn; };

async function request<T>(method: string, path: string, body?: unknown): Promise<T> {
  const headers: Record<string, string> = {};
  const token = tokenStore.get();
  if (token) headers.Authorization = `Bearer ${token}`;
  let payload: BodyInit | undefined;
  if (body instanceof FormData) {
    payload = body; // browser mengatur boundary multipart sendiri
  } else if (body !== undefined) {
    headers['Content-Type'] = 'application/json';
    payload = JSON.stringify(body);
  }

  let res: Response;
  try {
    res = await fetch(API_URL + path, { method, headers, body: payload });
  } catch {
    throw new ApiError('Tidak bisa terhubung ke server. Pastikan backend sudah berjalan.', 0);
  }

  const text = await res.text();
  let data: unknown = null;
  if (text) {
    try { data = JSON.parse(text); } catch { data = text; }
  }
  if (!res.ok) {
    const raw = (data as { message?: string | string[] } | null)?.message;
    const msg = Array.isArray(raw) ? raw.join(', ') : raw || `Terjadi kesalahan (${res.status})`;
    if (res.status === 401 && token && !path.startsWith('/auth/login')) onUnauthorized?.();
    throw new ApiError(msg, res.status);
  }
  return data as T;
}

export const api = {
  get: <T>(p: string) => request<T>('GET', p),
  post: <T>(p: string, b?: unknown) => request<T>('POST', p, b),
  patch: <T>(p: string, b?: unknown) => request<T>('PATCH', p, b),
  del: <T>(p: string) => request<T>('DELETE', p),
};
