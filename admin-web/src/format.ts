export const rupiah = (n: number) => 'Rp ' + n.toLocaleString('id-ID');

export const dateID = (iso: string) =>
  new Date(iso).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });

export const dateTimeID = (iso: string) =>
  new Date(iso).toLocaleString('id-ID', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' });

export const FACILITY_ICONS: { value: string; label: string; glyph: string }[] = [
  { value: 'fitness_center', label: 'Alat beban', glyph: '🏋️' },
  { value: 'directions_run', label: 'Kardio', glyph: '🏃' },
  { value: 'lock_outline', label: 'Loker', glyph: '🔒' },
  { value: 'shower_outlined', label: 'Kamar mandi', glyph: '🚿' },
  { value: 'wifi', label: 'Wi-Fi', glyph: '📶' },
  { value: 'self_improvement', label: 'Studio yoga', glyph: '🧘' },
  { value: 'hot_tub_outlined', label: 'Sauna', glyph: '♨️' },
  { value: 'sports_gymnastics', label: 'CrossFit / senam', glyph: '🤸' },
  { value: 'check_circle_outline', label: 'Lainnya', glyph: '✔️' },
];
export const glyphOf = (icon: string) => FACILITY_ICONS.find((i) => i.value === icon)?.glyph ?? '✔️';

export const GOAL_LABELS: Record<string, string> = {
  WEIGHT_LOSS: 'Turun berat badan',
  MUSCLE_GAIN: 'Naik massa otot',
  TONING: 'Bentuk tubuh',
  ENDURANCE: 'Stamina & daya tahan',
  REHAB: 'Pemulihan cedera',
  GENERAL: 'Kebugaran umum',
};
