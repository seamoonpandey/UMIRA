import { describe, it, expect, beforeAll, afterAll, beforeEach, vi } from "vitest";
import { getApp, closeApp, injectAuth } from "../helpers";
import type { FastifyInstance } from "fastify";

// Mock service functions to avoid hitting external APIs
vi.mock("../../modules/intervention/simplify.service.js", () => ({
  simplifyWithBart: vi.fn(),
}));

let app: FastifyInstance;

beforeAll(async () => {
  app = await getApp();
});

afterAll(async () => {
  await closeApp();
});

const headers = () => injectAuth(app);
const CUID = "clxdqz2a20000jz9b5x7g6h4q";

async function getPrisma() {
  return (await import("../../db/prisma")).prisma;
}

// ══════════════════════════════════════════════
// POST /v1/intervention/simplify
// ══════════════════════════════════════════════

describe("POST /v1/intervention/simplify", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("simplifies text using BART and returns result", async () => {
    const { simplifyWithBart } = await import("../../modules/intervention/simplify.service.js");
    (simplifyWithBart as any).mockResolvedValue("This is a simpler version of the text.");

    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/simplify",
      headers: headers(),
      payload: { text: "This is a very complex and hard to read piece of text that needs simplification." },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.simplified).toBe("This is a simpler version of the text.");
  });

  it("returns 400 for empty text", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/simplify",
      headers: headers(),
      payload: { text: "" },
    });

    expect(res.statusCode).toBe(400);
  });

  it("returns 401 without auth", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/simplify",
      payload: { text: "Some sufficiently long text for testing." },
    });

    expect(res.statusCode).toBe(401);
  });
});

// ══════════════════════════════════════════════
// POST /v1/intervention/sessions
// ══════════════════════════════════════════════

describe("POST /v1/intervention/sessions", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("saves a spelling session and returns its id", async () => {
    const p = await getPrisma() as any;
    p.interventionSession.create.mockResolvedValue({ id: CUID });

    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/sessions",
      headers: headers(),
      payload: { type: "spelling", score: 5, total: 7 },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.ok).toBe(true);
    expect(body.id).toBe(CUID);
  });

  it("saves a typing session with wpm and accuracy", async () => {
    const p = await getPrisma() as any;
    p.interventionSession.create.mockResolvedValue({ id: CUID });

    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/sessions",
      headers: headers(),
      payload: { type: "typing", wpm: 45, accuracy: 92 },
    });

    expect(res.statusCode).toBe(200);
    expect(JSON.parse(res.body).ok).toBe(true);
  });

  it("saves a lesson session with grapheme and phoneme", async () => {
    const p = await getPrisma() as any;
    p.interventionSession.create.mockResolvedValue({ id: CUID });

    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/sessions",
      headers: headers(),
      payload: { type: "lesson", grapheme: "th", phoneme: "ð" },
    });

    expect(res.statusCode).toBe(200);
    expect(JSON.parse(res.body).ok).toBe(true);
  });

  it("saves a practice session with stats", async () => {
    const p = await getPrisma() as any;
    p.interventionSession.create.mockResolvedValue({ id: CUID });

    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/sessions",
      headers: headers(),
      payload: { type: "practice", wpm: 85, stats: { skippedWords: 2, repetitions: 1 } },
    });

    expect(res.statusCode).toBe(200);
    expect(JSON.parse(res.body).ok).toBe(true);
  });

  it("returns 400 for invalid session type", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/sessions",
      headers: headers(),
      payload: { type: "invalid_type" },
    });

    expect(res.statusCode).toBe(400);
  });

  it("returns 400 for missing type", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/sessions",
      headers: headers(),
      payload: {},
    });

    expect(res.statusCode).toBe(400);
  });

  it("returns 401 without auth", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/sessions",
      payload: { type: "practice" },
    });

    expect(res.statusCode).toBe(401);
  });
});

// ══════════════════════════════════════════════
// GET /v1/intervention/sessions
// ══════════════════════════════════════════════

describe("GET /v1/intervention/sessions", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns an empty list when no sessions exist", async () => {
    const p = await getPrisma() as any;
    p.interventionSession.findMany.mockResolvedValue([]);

    const res = await app.inject({ method: "GET", url: "/v1/intervention/sessions", headers: headers() });

    expect(res.statusCode).toBe(200);
    expect(JSON.parse(res.body)).toEqual({ sessions: [] });
  });

  it("lists saved intervention sessions", async () => {
    const p = await getPrisma() as any;
    p.interventionSession.findMany.mockResolvedValue([
      { id: CUID, type: "spelling", createdAt: new Date("2025-06-01"), score: 5, total: 7, wpm: null, accuracy: null, grapheme: null },
      { id: "clxdqz2a20001jz9b5x7g6h4r", type: "typing", createdAt: new Date("2025-06-02"), score: null, total: null, wpm: 45, accuracy: 92, grapheme: null },
    ]);

    const res = await app.inject({ method: "GET", url: "/v1/intervention/sessions", headers: headers() });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.sessions).toHaveLength(2);
    expect(body.sessions[0].type).toBe("spelling");
    expect(body.sessions[0].score).toBe(5);
    expect(body.sessions[0].total).toBe(7);
    expect(body.sessions[1].type).toBe("typing");
    expect(body.sessions[1].wpm).toBe(45);
    expect(body.sessions[1].accuracy).toBe(92);
  });

  it("includes date string for each session", async () => {
    const p = await getPrisma() as any;
    p.interventionSession.findMany.mockResolvedValue([
      { id: CUID, type: "practice", createdAt: new Date("2025-06-15T12:30:00Z"), score: null, total: null, wpm: null, accuracy: null, grapheme: null },
    ]);

    const res = await app.inject({ method: "GET", url: "/v1/intervention/sessions", headers: headers() });

    expect(res.statusCode).toBe(200);
    const session = JSON.parse(res.body).sessions[0];
    expect(session.date).toBeDefined();
    expect(typeof session.date).toBe("string");
    expect(session.date).toContain("2025-06-15");
  });

  it("returns 401 without auth", async () => {
    const res = await app.inject({ method: "GET", url: "/v1/intervention/sessions" });
    expect(res.statusCode).toBe(401);
  });
});

// ══════════════════════════════════════════════
// POST /v1/intervention/analyze-practice
// ══════════════════════════════════════════════

describe("POST /v1/intervention/analyze-practice", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns 406 when request is not multipart", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/analyze-practice",
      headers: headers(),
      payload: {},
    });

    // @fastify/multipart returns 406 for non-multipart Content-Type
    expect(res.statusCode).toBe(406);
  });

  it("returns 401 without auth", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/analyze-practice",
      payload: {},
    });

    expect(res.statusCode).toBe(401);
  });
});

// ══════════════════════════════════════════════
// POST /v1/intervention/ocr
// ══════════════════════════════════════════════

describe("POST /v1/intervention/ocr", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns 406 when request is not multipart", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/ocr",
      headers: headers(),
      payload: {},
    });

    // @fastify/multipart returns 406 for non-multipart Content-Type
    expect(res.statusCode).toBe(406);
  });

  it("returns 401 without auth", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/ocr",
      payload: {},
    });

    expect(res.statusCode).toBe(401);
  });
});
