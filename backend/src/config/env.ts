import "dotenv/config";
import { z } from "zod";

const Env = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().default(4000),
  DATABASE_URL: z.string().url(),
  REDIS_URL: z.string().url().optional(),
  CORS_ORIGINS: z.string().default("http://localhost:8080"),
  JWT_SECRET: z.string().min(32, "JWT_SECRET must be at least 32 chars"),
  JWT_EXPIRES_IN: z.string().default("7d"),
  AI_PROVIDER: z.enum(["openai", "anthropic", "mock"]).default("mock"),
  OPENAI_API_KEY: z.string().optional(),
  OPENAI_MODEL: z.string().default("gpt-4o-mini"),
  ANTHROPIC_API_KEY: z.string().optional(),
  ANTHROPIC_MODEL: z.string().default("claude-haiku-4-5-20251001"),
  RATE_LIMIT_MAX_ANON: z.coerce.number().default(20),
  RATE_LIMIT_MAX_FREE: z.coerce.number().default(60),
  RATE_LIMIT_MAX_PRO: z.coerce.number().default(300),
  RATE_LIMIT_WINDOW: z.coerce.number().default(60_000),
  LOG_LEVEL: z.string().default("info"),
  SENTRY_DSN: z.string().url().optional(),
  SENTRY_ENVIRONMENT: z.string().optional(),
  PROMETHEUS_ENABLED: z.coerce.boolean().default(false),
});

export const env = Env.parse(process.env);
export type EnvT = typeof env;
