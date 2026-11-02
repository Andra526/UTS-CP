import { useCallback, useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { api } from './api';

/** Ambil data dari API + status loading/error + fungsi reload. */
export function useFetch<T>(path: string) {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    try {
      setError(null);
      setData(await api.get<T>(path));
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }, [path]);

  useEffect(() => { setLoading(true); void load(); }, [load]);
  return { data, setData, error, loading, reload: load };
}

/** Jalankan aksi dengan toast loading → sukses/gagal. Mengembalikan hasil atau undefined bila gagal. */
export async function withToast<T>(
  action: Promise<T>,
  msgs: { loading: string; success: string },
): Promise<T | undefined> {
  try {
    return await toast.promise(action, {
      loading: msgs.loading,
      success: msgs.success,
      error: (e: Error) => e.message,
    });
  } catch {
    return undefined;
  }
}
