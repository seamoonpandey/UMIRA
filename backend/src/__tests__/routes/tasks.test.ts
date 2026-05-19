import { describe, it, expect, beforeAll, afterAll, beforeEach, vi } from "vitest";
import { getApp, closeApp, injectAuth, mockTask } from "../helpers";
import type { FastifyInstance } from "fastify";

let app: FastifyInstance;

beforeAll(async () => {
  app = await getApp();
});

afterAll(async () => {
  await closeApp();
});

const headers = () => injectAuth(app);
const CUID = "clxdqz2a20000jz9b5x7g6h4q"; // valid CUID-like string
const CUID2 = "clxdqz2a20001jz9b5x7g6h4r";

async function getPrisma() {
  return (await import("../../db/prisma")).prisma;
}

// ══════════════════════════════════════════════
// GET /v1/tasks
// ══════════════════════════════════════════════

describe("GET /v1/tasks", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns an empty list when no tasks exist", async () => {
    const p = await getPrisma() as any;
    p.task.findMany.mockResolvedValue([]);

    const res = await app.inject({ method: "GET", url: "/v1/tasks", headers: headers() });

    expect(res.statusCode).toBe(200);
    expect(JSON.parse(res.body)).toEqual({ tasks: [] });
  });

  it("returns tasks for the authenticated user", async () => {
    const p = await getPrisma() as any;
    const tasks = [mockTask({ id: CUID }), mockTask({ id: CUID2, title: "Second task" })];
    p.task.findMany.mockResolvedValue(tasks);

    const res = await app.inject({ method: "GET", url: "/v1/tasks", headers: headers() });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.tasks).toHaveLength(2);
    expect(body.tasks[0].id).toBe(CUID);
  });

  it("returns 401 without auth", async () => {
    const res = await app.inject({ method: "GET", url: "/v1/tasks" });
    expect(res.statusCode).toBe(401);
  });
});

// ══════════════════════════════════════════════
// POST /v1/tasks
// ══════════════════════════════════════════════

describe("POST /v1/tasks", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("creates a task and returns 201", async () => {
    const p = await getPrisma() as any;
    p.task.create.mockResolvedValue(mockTask({ id: CUID }));
    p.auditLog.create.mockResolvedValue({});

    const res = await app.inject({
      method: "POST",
      url: "/v1/tasks",
      headers: headers(),
      payload: { title: "Write a blog post" },
    });

    expect(res.statusCode).toBe(201);
    const body = JSON.parse(res.body);
    expect(body.task.title).toBe("Test task");
  });

  it("accepts optional fields (sourceText, priority, dueAt)", async () => {
    const p = await getPrisma() as any;
    p.task.create.mockResolvedValue(mockTask({ id: CUID }));
    p.auditLog.create.mockResolvedValue({});

    const res = await app.inject({
      method: "POST",
      url: "/v1/tasks",
      headers: headers(),
      payload: {
        title: "Research project",
        sourceText: "Some notes",
        priority: "high",
        dueAt: "2025-06-01T00:00:00.000Z",
      },
    });

    expect(res.statusCode).toBe(201);
  });

  it("returns 400 for empty title", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/tasks",
      headers: headers(),
      payload: { title: "" },
    });
    expect(res.statusCode).toBe(400);
  });
});

// ══════════════════════════════════════════════
// PATCH /v1/tasks/:id
// ══════════════════════════════════════════════

describe("PATCH /v1/tasks/:id", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("updates a task", async () => {
    const p = await getPrisma() as any;
    p.task.findUnique.mockResolvedValue(mockTask({ id: CUID }));
    p.task.update.mockResolvedValue(mockTask({ id: CUID, status: "in_progress" }));
    p.auditLog.create.mockResolvedValue({});

    const res = await app.inject({
      method: "PATCH",
      url: `/v1/tasks/${CUID}`,
      headers: headers(),
      payload: { status: "in_progress" },
    });

    expect(res.statusCode).toBe(200);
    expect(JSON.parse(res.body).task.status).toBe("in_progress");
  });

  it("returns 400 for invalid task ID format", async () => {
    const res = await app.inject({
      method: "PATCH",
      url: "/v1/tasks/invalid-id",
      headers: headers(),
      payload: { status: "done" },
    });
    expect(res.statusCode).toBe(400);
  });
});

// ══════════════════════════════════════════════
// DELETE /v1/tasks/:id
// ══════════════════════════════════════════════

describe("DELETE /v1/tasks/:id", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("deletes a task and returns 204", async () => {
    const p = await getPrisma() as any;
    p.task.findUnique.mockResolvedValue(mockTask({ id: CUID }));
    p.task.delete.mockResolvedValue(mockTask());
    p.auditLog.create.mockResolvedValue({});

    const res = await app.inject({
      method: "DELETE",
      url: `/v1/tasks/${CUID}`,
      headers: headers(),
    });

    expect(res.statusCode).toBe(204);
  });
});

// ══════════════════════════════════════════════
// POST /v1/tasks/:id/microtasks/generate
// ══════════════════════════════════════════════

describe("POST /v1/tasks/:id/microtasks/generate", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("generates microtasks via the mock AI provider", async () => {
    const p = await getPrisma() as any;
    p.task.findUnique.mockResolvedValue(mockTask({ id: CUID }));
    p.aiJob.create.mockResolvedValue({ id: "aj1" });
    p.aiJob.update.mockResolvedValue({});
    p.microtask.deleteMany.mockResolvedValue({ count: 0 });
    p.microtask.createMany.mockResolvedValue({ count: 3 });
    p.auditLog.create.mockResolvedValue({});

    const res = await app.inject({
      method: "POST",
      url: `/v1/tasks/${CUID}/microtasks/generate`,
      headers: headers(),
      payload: { goal: "Write a blog post about neurodiversity" },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.ok).toBe(true);
  });

  it("returns refusal for unsafe goals", async () => {
    const p = await getPrisma() as any;
    p.task.findUnique.mockResolvedValue(mockTask({ id: CUID }));

    const res = await app.inject({
      method: "POST",
      url: `/v1/tasks/${CUID}/microtasks/generate`,
      headers: headers(),
      payload: { goal: "I want to hurt myself" },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.ok).toBe(false);
    expect(body.refusal).toBeTruthy();
  });
});
