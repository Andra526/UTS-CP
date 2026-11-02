/** Paket tujuan latihan yang dipilih member saat booking PT. */
export const GOAL_TYPES = [
  'WEIGHT_LOSS',
  'MUSCLE_GAIN',
  'TONING',
  'ENDURANCE',
  'REHAB',
  'GENERAL',
] as const;
export type GoalType = (typeof GOAL_TYPES)[number];
