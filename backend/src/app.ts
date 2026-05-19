import Fastify, { type FastifyInstance, type FastifyError, type FastifyBaseLogger } from "fastify";
import cors from "@fastify/cors";
import helmet from "@fastify/helmet";
import rateLimit from "@fastify/rate-limit";
import compress from "@fastify/compress";
import swagger from "@fastify/swagger";
import swaggerUi from "@fastify/swagger-ui";
import * as Sentry from "@sentry/node";

import { env } from "./config/env.js";
import { logger as appLogger } from "./config/logger.js";
import { initMetrics, getRegistry, metricsText, httpRequestsTotal, httpRequestDuration } from "./config/metrics.js";
import { registerJwt } from "./auth/jwt.js";
import { HttpError, tooManyRequests } from "./utils/errors.js";
import { prisma } from "./db/prisma.js";

import userRoutes from "./modules/users/users.routes.js";
import preferencesRoutes from "./modules/preferences/preferences.routes.js";
import tasksRoutes from "./modules/tasks/tasks.routes.js";
import readingRoutes from "./modules/reading/reading.routes.js";
import focusRoutes from "./modules/focus/focus.routes.js";
import analyticsRoutes from "./modules/analytics/analytics.routes.js";
import privacyRoutes from "./modules/privacy/privacy.routes.js";

export async function buildApp(): Promise<FastifyInstance> {
  initMetrics();
  const app = Fastify({ loggerInstance: appLogger as unknown as FastifyBaseLogger, trustProxy: true, bodyLimit: 1_000_000 });

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

  /* ── Parse JWT before rate-limit (key + tier) ───────────────────── */

  app.addHook("onRequest", async (req) => {
    const header = req.headers.authorization;
    if (!header?.startsWith("Bearer ")) return;
    try {
      const decoded = app.jwt.decode(header.slice(7));
      if (decoded && typeof decoded === "object" && "id" in decoded) {
        req.user = decoded as any;
      }
    } catch {
      // invalid token — continue as anonymous for rate-limiting purposes
    }
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
    keyGenerator: (req) => req.user?.id ?? req.ip,
    max: (req) => {
      const tier = (req.user as any)?.tier ?? "anon";
      if (tier === "pro") return env.RATE_LIMIT_MAX_PRO;
      if (tier === "free") return env.RATE_LIMIT_MAX_FREE;
      return env.RATE_LIMIT_MAX_ANON;
    },
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

  /* ── Request instrumentation ─────────────────────────────────────── */

  app.addHook("onResponse", (_req, reply, done) => {
    if (httpRequestsTotal && httpRequestDuration) {
      const route = reply.request.routeOptions?.url ?? "unknown";
      const method = reply.request.method;
      const status = String(reply.statusCode);

      httpRequestsTotal.inc({ method, route, status });
      httpRequestDuration.observe(
        { method, route, status },
        reply.elapsedTime / 1000,
      );
    }
    done();
  });

  /* ── Health, Metrics & Info ──────────────────────────────────────── */

  app.get("/health", async () => {
    let dbStatus = "ok";
    try {
      await prisma.$queryRaw`SELECT 1`;
    } catch {
      dbStatus = "error";
    }

    const registry = getRegistry();

    return {
      status: dbStatus === "ok" ? "ok" : "degraded",
      ts: Date.now(),
      uptime: process.uptime(),
      database: dbStatus,
      metrics: registry ? "enabled" : "disabled",
    };
  });

  if (env.PROMETHEUS_ENABLED) {
    app.get("/metrics", async (_req, reply) => {
      reply.header("Content-Type", getRegistry()?.contentType ?? "text/plain");
      return metricsText();
    });
  }

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
