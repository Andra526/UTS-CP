/** Hapus passwordHash sebelum data user dikirim ke klien. */
export function toPublicUser<T extends { passwordHash?: string }>(user: T) {
  const { passwordHash: _omit, ...rest } = user;
  return rest;
}

export const DAY_NAMES = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];
