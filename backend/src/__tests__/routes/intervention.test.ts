import { describe, it, expect, beforeAll, afterAll, beforeEach, vi } from "vitest";
import { getApp, closeApp, injectAuth } from "../helpers";
import type { FastifyInstance } from "fastify";
import FormData from "form-data";

// ── Helpers ────────────────────────────────────────────────

function createTestWav(): Buffer {
  const sampleRate = 44100;
  const bitsPerSample = 16;
  const numChannels = 1;
  const dataSize = 176;
  const headerSize = 44;
  const fileSize = headerSize + dataSize - 8;

  const buf = Buffer.alloc(headerSize + dataSize);
  buf.write("RIFF", 0);
  buf.writeUInt32LE(fileSize, 4);
  buf.write("WAVE", 8);
  buf.write("fmt ", 12);
  buf.writeUInt32LE(16, 16);
  buf.writeUInt16LE(1, 20);
  buf.writeUInt16LE(numChannels, 22);
  buf.writeUInt32LE(sampleRate, 24);
  buf.writeUInt32LE(sampleRate * numChannels * bitsPerSample / 8, 28);
  buf.writeUInt16LE(numChannels * bitsPerSample / 8, 32);
  buf.writeUInt16LE(bitsPerSample, 34);
  buf.write("data", 36);
  buf.writeUInt32LE(dataSize, 40);
  return buf;
}

function buildMultipart(opts: { files?: { name: string; filename: string; contentType: string; buffer: Buffer }[]; fields?: Record<string, string> }): { headers: Record<string, string>; body: Buffer } {
  const form = new FormData();
  if (opts.files) {
    for (const f of opts.files) {
      form.append(f.name, f.buffer, { filename: f.filename, contentType: f.contentType });
    }
  }
  if (opts.fields) {
    for (const [key, val] of Object.entries(opts.fields)) {
      form.append(key, val);
    }
  }
  return { headers: form.getHeaders() as Record<string, string>, body: form.getBuffer() };
}

// Mock service functions to avoid hitting external APIs
vi.mock("../../modules/intervention/simplify.service.js", () => ({
  simplifyWithBart: vi.fn(),
}));

vi.mock("../../modules/intervention/intervention.service.js", () => ({
  analyzePracticeAudio: vi.fn(),
}));

vi.mock("../../modules/intervention/ocr.service.js", () => ({
  performOcr: vi.fn(),
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

  it("analyzes an audio file and returns word data and stats", async () => {
    const { analyzePracticeAudio } = await import("../../modules/intervention/intervention.service.js");
    (analyzePracticeAudio as any).mockResolvedValue({
      wordData: [
        { word: "the", status: "correct", start: 0.1, end: 0.3, pauseMs: 0, durationRatio: 0.5, speechRateWpm: 120 },
        { word: "boy", status: "correct", start: 0.4, end: 0.6, pauseMs: 100, durationRatio: 0.5, speechRateWpm: 125 },
      ],
      stats: { skippedWords: 0, repetitions: 0, wpm: 122.5 },
    });

    const wav = createTestWav();
    const mp = buildMultipart({
      files: [{ name: "file", filename: "test.wav", contentType: "audio/wav", buffer: wav }],
      fields: { expectedText: "the boy went to the store" },
    });

    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/analyze-practice",
      headers: { ...headers(), ...mp.headers },
      payload: mp.body,
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.wordData).toHaveLength(2);
    expect(body.wordData[0].word).toBe("the");
    expect(body.wordData[0].status).toBe("correct");
    expect(body.stats.skippedWords).toBe(0);
    expect(body.stats.wpm).toBe(122.5);
  });

  it("uses default expected text when field is missing", async () => {
    const { analyzePracticeAudio } = await import("../../modules/intervention/intervention.service.js");
    (analyzePracticeAudio as any).mockResolvedValue({
      wordData: [{ word: "the", status: "correct", start: 0.1, end: 0.3, pauseMs: 0, durationRatio: 0.5, speechRateWpm: 100 }],
      stats: { skippedWords: 0, repetitions: 0, wpm: 100 },
    });

    const wav = createTestWav();
    const mp = buildMultipart({
      files: [{ name: "file", filename: "test.wav", contentType: "audio/wav", buffer: wav }],
    });

    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/analyze-practice",
      headers: { ...headers(), ...mp.headers },
      payload: mp.body,
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.wordData).toHaveLength(1);
    // verify the service was called with the default expected text
    expect(analyzePracticeAudio).toHaveBeenCalledWith(
      expect.any(Buffer),
      expect.any(String),
      "The boy went to the store to buy some candy.",
    );
  });

  it("forwards custom expectedText field to the service", async () => {
    const { analyzePracticeAudio } = await import("../../modules/intervention/intervention.service.js");
    (analyzePracticeAudio as any).mockResolvedValue({
      wordData: [],
      stats: { skippedWords: 0, repetitions: 0, wpm: 0 },
    });

    const wav = createTestWav();
    const mp = buildMultipart({
      files: [{ name: "file", filename: "test.wav", contentType: "audio/wav", buffer: wav }],
      fields: { expectedText: "custom text for analysis" },
    });

    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/analyze-practice",
      headers: { ...headers(), ...mp.headers },
      payload: mp.body,
    });

    expect(res.statusCode).toBe(200);
    expect(analyzePracticeAudio).toHaveBeenCalledWith(
      expect.any(Buffer),
      expect.any(String),
      "custom text for analysis",
    );
  });

  it("handles service errors gracefully", async () => {
    const { analyzePracticeAudio } = await import("../../modules/intervention/intervention.service.js");
    (analyzePracticeAudio as any).mockRejectedValue(new Error("Groq API rate limit exceeded"));

    const wav = createTestWav();
    const mp = buildMultipart({
      files: [{ name: "file", filename: "test.wav", contentType: "audio/wav", buffer: wav }],
    });

    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/analyze-practice",
      headers: { ...headers(), ...mp.headers },
      payload: mp.body,
    });

    expect(res.statusCode).toBe(500);
    const body = JSON.parse(res.body);
    expect(body.error).toContain("Groq API rate limit exceeded");
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

  it("extracts text from an uploaded image", async () => {
    const { performOcr } = await import("../../modules/intervention/ocr.service.js");
    (performOcr as any).mockResolvedValue("Extracted text from the image.");

    const img = Buffer.from("fake-png-data");
    const mp = buildMultipart({
      files: [{ name: "image", filename: "scan.png", contentType: "image/png", buffer: img }],
    });

    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/ocr",
      headers: { ...headers(), ...mp.headers },
      payload: mp.body,
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.text).toBe("Extracted text from the image.");
  });

  it("handles OCR service errors gracefully", async () => {
    const { performOcr } = await import("../../modules/intervention/ocr.service.js");
    (performOcr as any).mockRejectedValue(new Error("Tesseract failed to process"));

    const img = Buffer.from("fake-png-data");
    const mp = buildMultipart({
      files: [{ name: "image", filename: "scan.png", contentType: "image/png", buffer: img }],
    });

    const res = await app.inject({
      method: "POST",
      url: "/v1/intervention/ocr",
      headers: { ...headers(), ...mp.headers },
      payload: mp.body,
    });

    expect(res.statusCode).toBe(500);
    const body = JSON.parse(res.body);
    expect(body.error).toContain("Tesseract failed to process");
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
