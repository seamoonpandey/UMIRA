import { describe, it, expect, beforeAll, afterAll, beforeEach, vi } from "vitest";
import { getApp, closeApp, injectAuth } from "../helpers";
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
// GET /v1/privacy/export
// ══════════════════════════════════════════════

describe("GET /v1/privacy/export", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("exports all user data", async () => {
    const prisma = (await import("../../db/prisma")).prisma;
    (prisma.user.findUnique as any).mockResolvedValue({
      id: "u1",
      email: "test@umira.app",
      locale: "en",
      timezone: "UTC",
      createdAt: new Date(),
      marketingOptIn: true,
      consentVersion: "v1",
    });
    (prisma.userPreference.findUnique as any).mockResolvedValue({ textDensity: "comfortable" });
    (prisma.task.findMany as any).mockResolvedValue([]);
    (prisma.textSession.findMany as any).mockResolvedValue([]);
    (prisma.focusSession.findMany as any).mockResolvedValue([]);
    (prisma.analyticsEvent.findMany as any).mockResolvedValue([]);
    (prisma.aiJob.findMany as any).mockResolvedValue([]);
    (prisma.auditLog.create as any).mockResolvedValue({});

    const res = await app.inject({ method: "GET", url: "/v1/privacy/export", headers: headers() });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.user.email).toBe("test@umira.app");
    expect(body.preferences).toBeDefined();
    expect(body.tasks).toBeDefined();
    expect(body.textSessions).toBeDefined();
    expect(body.focusSessions).toBeDefined();
    expect(body.analyticsEvents).toBeDefined();
    expect(body.aiJobs).toBeDefined();
    expect(body.exported_at).toBeTruthy();
  });

  it("returns 401 without auth", async () => {
    const res = await app.inject({ method: "GET", url: "/v1/privacy/export" });
    expect(res.statusCode).toBe(401);
  });
});

// ══════════════════════════════════════════════
// DELETE /v1/privacy/account
// ══════════════════════════════════════════════

describe("DELETE /v1/privacy/account", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("hard-deletes the user account and returns 204", async () => {
    const prisma = (await import("../../db/prisma")).prisma;
    (prisma.user.delete as any).mockResolvedValue({});
    (prisma.auditLog.create as any).mockResolvedValue({});

    const res = await app.inject({
      method: "DELETE",
      url: "/v1/privacy/account",
      headers: headers(),
    });

    expect(res.statusCode).toBe(204);
  });

  it("returns 401 without auth", async () => {
    const res = await app.inject({ method: "DELETE", url: "/v1/privacy/account" });
    expect(res.statusCode).toBe(401);
  });
});
