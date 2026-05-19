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
// POST /v1/reading/simplify
// ══════════════════════════════════════════════

describe("POST /v1/reading/simplify", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("simplifies text (no save) and returns result", async () => {
    const prisma = (await import("../../db/prisma")).prisma;
    (prisma.aiJob.create as any).mockResolvedValue({ id: "aj1" });
    (prisma.aiJob.update as any).mockResolvedValue({});

    const res = await app.inject({
      method: "POST",
      url: "/v1/reading/simplify",
      headers: headers(),
      payload: {
        text: "Neurodiversity is the concept that neurological differences like autism and ADHD are natural variations of the human brain rather than disorders that need to be cured. Many workplaces are now adopting neurodiversity-friendly policies to leverage the unique strengths of neurodivergent employees, such as pattern recognition and creative problem-solving.",
        level: "medium",
      },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.ok).toBe(true);
    expect(body.result).toBeDefined();
    expect(body.result.summary).toBeTruthy();
  });

  it("saves session when save=true", async () => {
    const prisma = (await import("../../db/prisma")).prisma;
    (prisma.aiJob.create as any).mockResolvedValue({ id: "aj1" });
    (prisma.aiJob.update as any).mockResolvedValue({});
    (prisma.textSession.create as any).mockResolvedValue({
      id: "session1",
      chunks: [],
    });
    (prisma.auditLog.create as any).mockResolvedValue({});

    const res = await app.inject({
      method: "POST",
      url: "/v1/reading/simplify",
      headers: headers(),
      payload: {
        text: "Neurodiversity is the concept that neurological differences like autism and ADHD are natural variations of the human brain rather than disorders that need to be cured. Many workplaces are now adopting neurodiversity-friendly policies to leverage the unique strengths of neurodivergent employees, such as pattern recognition and creative problem-solving.",
        level: "medium",
        save: true,
      },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.ok).toBe(true);
    expect(body.session).toBeDefined();
    expect(body.session.id).toBe("session1");
  });

  it("returns 400 for text under 20 chars", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/reading/simplify",
      headers: headers(),
      payload: { text: "Too short", level: "light" },
    });

    expect(res.statusCode).toBe(400);
  });

  it("returns 401 without auth", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/reading/simplify",
      payload: { text: "Some sufficiently long text for testing purposes here.", level: "medium" },
    });

    expect(res.statusCode).toBe(401);
  });
});

// ══════════════════════════════════════════════
// GET /v1/reading/sessions
// ══════════════════════════════════════════════

describe("GET /v1/reading/sessions", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("lists saved reading sessions", async () => {
    const prisma = (await import("../../db/prisma")).prisma;
    (prisma.textSession.findMany as any).mockResolvedValue([
      { id: "s1", sourceType: "paste", readabilityTarget: "medium", createdAt: new Date(), simplifiedText: "summary" },
    ]);

    const res = await app.inject({ method: "GET", url: "/v1/reading/sessions", headers: headers() });

    expect(res.statusCode).toBe(200);
    expect(JSON.parse(res.body).sessions).toHaveLength(1);
  });
});
