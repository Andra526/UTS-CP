export const databaseConfig = () => ({
  databaseUrl: process.env.DATABASE_URL ?? 'file:./dev.db',
});
