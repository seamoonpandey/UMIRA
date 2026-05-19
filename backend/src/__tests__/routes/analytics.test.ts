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
// POST /v1/analytics/events
// ══════════════════════════════════════════════

describe("POST /v1/analytics/events", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("tracks an event and returns 204", async () => {
    const prisma = (await import("../../db/prisma")).prisma;
    (prisma.analyticsEvent.create as any).mockResolvedValue({ id: "evt1" });

    const res = await app.inject({
      method: "POST",
      url: "/v1/analytics/events",
      headers: headers(),
      payload: { eventName: "page_view" },
    });

    expect(res.statusCode).toBe(204);
  });

  it("tracks an event with properties", async () => {
    const prisma = (await import("../../db/prisma")).prisma;
    (prisma.analyticsEvent.create as any).mockResolvedValue({ id: "evt2" });

    const res = await app.inject({
      method: "POST",
      url: "/v1/analytics/events",
      headers: headers(),
      payload: { eventName: "task_created", props: { source: "manual", priority: "high" } },
    });

    expect(res.statusCode).toBe(204);
  });

  it("returns 400 for empty event name", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/analytics/events",
      headers: headers(),
      payload: { eventName: "" },
    });
    expect(res.statusCode).toBe(400);
  });

  it("returns 401 without auth", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/analytics/events",
      payload: { eventName: "page_view" },
    });
    expect(res.statusCode).toBe(401);
  });
});

// ══════════════════════════════════════════════
// GET /v1/analytics/summary
// ══════════════════════════════════════════════

describe("GET /v1/analytics/summary", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns a summary of user activity", async () => {
    const prisma = (await import("../../db/prisma")).prisma;
    (prisma.task.count as any).mockResolvedValue(5);
    (prisma.microtask.count as any).mockResolvedValue(12);
    (prisma.focusSession.count as any).mockResolvedValue(3);
    (prisma.focusSession.aggregate as any).mockResolvedValue({ _sum: { actualMinutes: 120 } });
    (prisma.textSession.count as any).mockResolvedValue(8);
    (prisma.focusSession.findMany as any).mockResolvedValue([
      { plannedMinutes: 25, actualMinutes: 22 },
      { plannedMinutes: 15, actualMinutes: 18 },
    ]);

    const res = await app.inject({ method: "GET", url: "/v1/analytics/summary", headers: headers() });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.tasks_created).toBe(5);
    expect(body.microtasks_done).toBe(12);
    expect(body.focus_completed).toBe(3);
    expect(body.focus_total_minutes).toBe(120);
    expect(body.reading_sessions).toBe(8);
    expect(body.estimation_accuracy).toBeDefined();
    expect(body.estimation_accuracy.avg_planned_minutes).toBe(20);
    expect(body.estimation_accuracy.avg_actual_minutes).toBe(20);
  });

  it("returns empty summary when no activity exists", async () => {
    const prisma = (await import("../../db/prisma")).prisma;
    (prisma.task.count as any).mockResolvedValue(0);
    (prisma.microtask.count as any).mockResolvedValue(0);
    (prisma.focusSession.count as any).mockResolvedValue(0);
    (prisma.focusSession.aggregate as any).mockResolvedValue({ _sum: { actualMinutes: null } });
    (prisma.textSession.count as any).mockResolvedValue(0);
    (prisma.focusSession.findMany as any).mockResolvedValue([]);

    const res = await app.inject({ method: "GET", url: "/v1/analytics/summary", headers: headers() });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.tasks_created).toBe(0);
    expect(body.focus_total_minutes).toBe(0);
    expect(body.estimation_accuracy.avg_planned_minutes).toBe(0);
    expect(body.estimation_accuracy.avg_actual_minutes).toBe(0);
  });
});
