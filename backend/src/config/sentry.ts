import * as Sentry from "@sentry/node";
import { env } from "./env.js";
import { logger } from "./logger.js";

export function initSentry(): void {
  if (!env.SENTRY_DSN) {
    logger.info("Sentry DSN not configured — skipping initialization");
    return;
  }
  Sentry.init({
    dsn: env.SENTRY_DSN,
    environment: env.SENTRY_ENVIRONMENT || env.NODE_ENV,
    tracesSampleRate: env.NODE_ENV === "production" ? 0.1 : 0,
    integrations: [Sentry.fastifyIntegration()],
  });
  logger.info("Sentry initialized");
}
