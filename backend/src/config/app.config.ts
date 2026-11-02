export const appConfig = () => ({
  port: parseInt(process.env.PORT ?? '3000', 10),
  jwtSecret: process.env.JWT_SECRET ?? 'dev-secret-ubah-di-produksi',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? '7d',
});
