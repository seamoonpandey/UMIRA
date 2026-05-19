import Fastify, { type FastifyInstance, type FastifyError } from "fastify";
import cors from "@fastify/cors";
import helmet from "@fastify/helmet";
import rateLimit from "@fastify/rate-limit";
import sensible from "@fastify/sensible";
import { ZodError } from "zod";

import { env } from "./config/env.js";
import { logger } from "./config/logger.js";
import { registerJwt } from "./auth/jwt.js";
import { HttpError } from "./utils/errors.js";

import userRoutes from "./modules/users/users.routes.js";
import preferencesRoutes from "./modules/preferences/preferences.routes.js";
import tasksRoutes from "./modules/tasks/tasks.routes.js";
import readingRoutes from "./modules/reading/reading.routes.js";
import focusRoutes from "./modules/focus/focus.routes.js";
import analyticsRoutes from "./modules/analytics/analytics.routes.js";
import privacyRoutes from "./modules/privacy/privacy.routes.js";

export async function buildApp(): Promise<FastifyInstance> {
  const app = Fastify({ logger, trustProxy: true, bodyLimit: 1_000_000 });

  await app.register(helmet, { contentSecurityPolicy: false });
  await app.register(cors, {
    origin: env.CORS_ORIGINS.split(",").map((s) => s.trim()),
    credentials: true,
  });
  await app.register(sensible);
  await app.register(rateLimit, {
    max: env.RATE_LIMIT_MAX,
    timeWindow: env.RATE_LIMIT_WINDOW,
  });
  await registerJwt(app);

  app.setErrorHandler((err: FastifyError | HttpError | ZodError, _req, reply) => {
    if (err instanceof ZodError) {
      return reply.code(400).send({ error: "validation_error", details: err.flatten() });
    }
    if (err instanceof HttpError) {
      return reply.code(err.statusCode).send({ error: err.message, code: err.code });
    }
    logger.error({ err }, "unhandled error");
    return reply.code(err.statusCode ?? 500).send({ error: "internal_error" });
  });

  app.get("/health", async () => ({ status: "ok", ts: Date.now() }));
  app.get("/", async () => ({
    name: "UMIRA API",
    version: "1.0.0",
    docs: "https://github.com/seamoonpandey/UMIRA",
  }));

  await app.register(userRoutes, { prefix: "/v1" });
  await app.register(preferencesRoutes, { prefix: "/v1" });
  await app.register(tasksRoutes, { prefix: "/v1" });
  await app.register(readingRoutes, { prefix: "/v1" });
  await app.register(focusRoutes, { prefix: "/v1" });
  await app.register(analyticsRoutes, { prefix: "/v1" });
  await app.register(privacyRoutes, { prefix: "/v1" });

  return app;
}
