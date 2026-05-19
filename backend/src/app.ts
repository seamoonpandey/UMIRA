import Fastify, { type FastifyInstance, type FastifyError } from "fastify";
import cors from "@fastify/cors";
import helmet from "@fastify/helmet";
import rateLimit from "@fastify/rate-limit";
import compress from "@fastify/compress";
import swagger from "@fastify/swagger";
import swaggerUi from "@fastify/swagger-ui";
import * as Sentry from "@sentry/node";

import { env } from "./config/env.js";
import { logger as appLogger } from "./config/logger.js";
import { registerJwt } from "./auth/jwt.js";
import { HttpError } from "./utils/errors.js";
import { prisma } from "./db/prisma.js";

import userRoutes from "./modules/users/users.routes.js";
import preferencesRoutes from "./modules/preferences/preferences.routes.js";
import tasksRoutes from "./modules/tasks/tasks.routes.js";
import readingRoutes from "./modules/reading/reading.routes.js";
import focusRoutes from "./modules/focus/focus.routes.js";
import analyticsRoutes from "./modules/analytics/analytics.routes.js";
import privacyRoutes from "./modules/privacy/privacy.routes.js";

export async function buildApp(): Promise<FastifyInstance> {
  const app = Fastify({ logger: true, trustProxy: true, bodyLimit: 1_000_000 });

  /* ── Error Handler (set early; last registration wins) ───────────── */

  app.setErrorHandler((err: FastifyError, _req, reply) => {
    // ZodError — duck type check (handles module duplication)
    if (Array.isArray((err as any).issues) && typeof (err as any).flatten === "function") {
      return reply
        .code(400)
        .send({ error: "validation_error", details: (err as any).flatten() });
    }

    // Custom HttpError
    if (err instanceof HttpError) {
      return reply
        .code(err.statusCode)
        .send({ error: err.message, code: err.code });
    }

    // Fastify HTTP errors with a client statusCode
    if (typeof err.statusCode === "number" && err.statusCode >= 400 && err.statusCode < 500) {
      return reply.code(err.statusCode).send({ error: err.message });
    }

    appLogger.error({ err }, "unhandled error");
    try {
      Sentry.captureException(err);
    } catch {
      // Sentry may not be initialized
    }
    return reply
      .code(err.statusCode ?? 500)
      .send({ error: "internal_error" });
  });

  /* ── Security ────────────────────────────────────────────────────── */

  await app.register(helmet, {
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'", "'unsafe-inline'"],
        styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
        fontSrc: ["'self'", "https://fonts.gstatic.com"],
        imgSrc: ["'self'", "data:"],
        connectSrc: ["'self'", ...env.CORS_ORIGINS.split(",").map((s) => s.trim())],
      },
    },
  });

  await app.register(cors, {
    origin: env.CORS_ORIGINS.split(",").map((s) => s.trim()),
    credentials: true,
  });

  await app.register(rateLimit, {
    max: env.RATE_LIMIT_MAX,
    timeWindow: env.RATE_LIMIT_WINDOW,
  });

  await app.register(compress);
  await registerJwt(app);

  /* ── API Documentation ───────────────────────────────────────────── */

  await app.register(swagger, {
    openapi: {
      info: {
        title: "UMIRA API",
        version: "1.0.0",
        description:
          "Neurodiversity-centered cognitive support API. Provides task management, reading simplification, focus sessions, analytics, and user preferences.",
      },
      servers: [{ url: `http://localhost:${env.PORT}` }],
    },
  });
  await app.register(swaggerUi, { routePrefix: "/docs" });

  /* ── Health & Info ───────────────────────────────────────────────── */

  app.get("/health", async () => {
    let dbStatus = "ok";
    try {
      await prisma.$queryRaw`SELECT 1`;
    } catch {
      dbStatus = "error";
    }

    return {
      status: dbStatus === "ok" ? "ok" : "degraded",
      ts: Date.now(),
      uptime: process.uptime(),
      database: dbStatus,
    };
  });

  app.get("/", async () => ({
    name: "UMIRA API",
    version: "1.0.0",
    docs: "/docs",
  }));

  /* ── Routes ──────────────────────────────────────────────────────── */

  await app.register(userRoutes, { prefix: "/v1" });
  await app.register(preferencesRoutes, { prefix: "/v1" });
  await app.register(tasksRoutes, { prefix: "/v1" });
  await app.register(readingRoutes, { prefix: "/v1" });
  await app.register(focusRoutes, { prefix: "/v1" });
  await app.register(analyticsRoutes, { prefix: "/v1" });
  await app.register(privacyRoutes, { prefix: "/v1" });

  return app;
}
