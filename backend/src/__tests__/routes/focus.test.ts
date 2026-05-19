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
const CUID = "clxdqz2a20000jz9b5x7g6h4q";
const CUID2 = "clxdqz2a20001jz9b5x7g6h4r";

async function getPrisma() {
  return (await import("../../db/prisma")).prisma;
}

// ══════════════════════════════════════════════
// POST /v1/focus/sessions (start)
// ══════════════════════════════════════════════

describe("POST /v1/focus/sessions", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("starts a focus session and returns 201", async () => {
    const p = await getPrisma() as any;
    p.focusSession.create.mockResolvedValue({
      id: CUID,
      userId: "test_user_id",
      plannedMinutes: 25,
      status: "running",
      startedAt: new Date(),
    });
    p.auditLog.create.mockResolvedValue({});

    const res = await app.inject({
      method: "POST",
      url: "/v1/focus/sessions",
      headers: headers(),
      payload: { plannedMinutes: 25 },
    });

    expect(res.statusCode).toBe(201);
    const body = JSON.parse(res.body);
    expect(body.session.status).toBe("running");
    expect(body.session.plannedMinutes).toBe(25);
  });

  it("starts a focus session linked to a task", async () => {
    const p = await getPrisma() as any;
    p.focusSession.create.mockResolvedValue({
      id: CUID2,
      userId: "test_user_id",
      taskId: CUID,
      plannedMinutes: 15,
      status: "running",
      startedAt: new Date(),
    });
    p.auditLog.create.mockResolvedValue({});

    const res = await app.inject({
      method: "POST",
      url: "/v1/focus/sessions",
      headers: headers(),
      payload: { plannedMinutes: 15, taskId: CUID },
    });

    expect(res.statusCode).toBe(201);
  });

  it("returns 400 for invalid plannedMinutes (too low)", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/focus/sessions",
      headers: headers(),
      payload: { plannedMinutes: 2 },
    });
    expect(res.statusCode).toBe(400);
  });
});

// ══════════════════════════════════════════════
// POST /v1/focus/sessions/:id/complete
// ══════════════════════════════════════════════

describe("POST /v1/focus/sessions/:id/complete", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("completes a focus session", async () => {
    const p = await getPrisma() as any;
    p.focusSession.findUnique.mockResolvedValue({
      id: CUID,
      userId: "test_user_id",
      taskId: null,
      plannedMinutes: 25,
      status: "running",
    });
    p.focusSession.update.mockResolvedValue({
      id: CUID,
      status: "completed",
      actualMinutes: 22,
      distractionEvents: 3,
    });
    p.auditLog.create.mockResolvedValue({});

    const res = await app.inject({
      method: "POST",
      url: `/v1/focus/sessions/${CUID}/complete`,
      headers: headers(),
      payload: { actualMinutes: 22, distractionEvents: 3 },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.session.status).toBe("completed");
    expect(body.session.actualMinutes).toBe(22);
  });
});

// ══════════════════════════════════════════════
// POST /v1/focus/sessions/:id/cancel
// ══════════════════════════════════════════════

describe("POST /v1/focus/sessions/:id/cancel", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("cancels a focus session", async () => {
    const p = await getPrisma() as any;
    p.focusSession.findUnique.mockResolvedValue({
      id: CUID,
      userId: "test_user_id",
    });
    p.focusSession.update.mockResolvedValue({
      id: CUID,
      status: "cancelled",
    });
    p.auditLog.create.mockResolvedValue({});

    const res = await app.inject({
      method: "POST",
      url: `/v1/focus/sessions/${CUID}/cancel`,
      headers: headers(),
      payload: {},
    });

    expect(res.statusCode).toBe(200);
    expect(JSON.parse(res.body).session.status).toBe("cancelled");
  });
});

// ══════════════════════════════════════════════
// GET /v1/focus/sessions
// ══════════════════════════════════════════════

describe("GET /v1/focus/sessions", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("lists focus sessions", async () => {
    const p = await getPrisma() as any;
    p.focusSession.findMany.mockResolvedValue([
      { id: CUID, plannedMinutes: 25, status: "completed", createdAt: new Date() },
    ]);

    const res = await app.inject({ method: "GET", url: "/v1/focus/sessions", headers: headers() });

    expect(res.statusCode).toBe(200);
    expect(JSON.parse(res.body).sessions).toHaveLength(1);
  });
});
