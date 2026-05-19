import { describe, it, expect, beforeAll, afterAll, beforeEach, vi } from "vitest";
import { getApp, closeApp, injectAuth, mockPreferences } from "../helpers";
import type { FastifyInstance } from "fastify";

let app: FastifyInstance;

beforeAll(async () => {
  app = await getApp();
});

afterAll(async () => {
  await closeApp();
});

const headers = () => injectAuth(app);

// ══════════════════════════════════════════════
// GET /v1/preferences
// ══════════════════════════════════════════════

describe("GET /v1/preferences", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns existing preferences", async () => {
    const prisma = (await import("../../db/prisma")).prisma;
    (prisma.userPreference.findUnique as any).mockResolvedValue(mockPreferences());

    const res = await app.inject({ method: "GET", url: "/v1/preferences", headers: headers() });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.preferences.textDensity).toBe("comfortable");
    expect(body.preferences.fontScale).toBe(1.0);
  });

  it("creates default preferences when none exist", async () => {
    const prisma = (await import("../../db/prisma")).prisma;
    (prisma.userPreference.findUnique as any).mockResolvedValue(null);
    (prisma.userPreference.create as any).mockResolvedValue(mockPreferences());

    const res = await app.inject({ method: "GET", url: "/v1/preferences", headers: headers() });

    expect(res.statusCode).toBe(200);
    expect(JSON.parse(res.body).preferences).toBeDefined();
  });
});

// ══════════════════════════════════════════════
// PATCH /v1/preferences
// ══════════════════════════════════════════════

describe("PATCH /v1/preferences", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("updates existing preferences", async () => {
    const prisma = (await import("../../db/prisma")).prisma;
    (prisma.userPreference.upsert as any).mockResolvedValue(
      mockPreferences({ textDensity: "spacious", reducedMotion: true }),
    );
    (prisma.auditLog.create as any).mockResolvedValue({});

    const res = await app.inject({
      method: "PATCH",
      url: "/v1/preferences",
      headers: headers(),
      payload: { textDensity: "spacious", reducedMotion: true },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.preferences.textDensity).toBe("spacious");
    expect(body.preferences.reducedMotion).toBe(true);
  });

  it("rejects invalid font scale values", async () => {
    const res = await app.inject({
      method: "PATCH",
      url: "/v1/preferences",
      headers: headers(),
      payload: { fontScale: 5.0 },
    });

    expect(res.statusCode).toBe(400);
  });

  it("rejects invalid text density enum", async () => {
    const res = await app.inject({
      method: "PATCH",
      url: "/v1/preferences",
      headers: headers(),
      payload: { textDensity: "super_dense" },
    });

    expect(res.statusCode).toBe(400);
  });
});
