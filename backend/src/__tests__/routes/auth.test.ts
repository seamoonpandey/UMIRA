import { describe, it, expect, beforeAll, afterAll, beforeEach, vi } from "vitest";
import { getApp, closeApp, injectAuth, mockUser } from "../helpers";
import type { FastifyInstance } from "fastify";

// Mock password hash so verifyPassword returns true without real argon2
vi.mock("../../auth/hash", () => ({
  hashPassword: vi.fn(() => Promise.resolve("$argon2id$v=19$m=65536,t=3,p=4$mocked_hash")),
  verifyPassword: vi.fn(() => Promise.resolve(true)),
}));

let app: FastifyInstance;

beforeAll(async () => {
  app = await getApp();
});

afterAll(async () => {
  await closeApp();
});

async function getPrisma() {
  return (await import("../../db/prisma")).prisma;
}

// ══════════════════════════════════════════════
// POST /v1/auth/signup
// ══════════════════════════════════════════════

describe("POST /v1/auth/signup", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("creates a user and returns 201 with JWT", async () => {
    const p = await getPrisma() as any;
    p.user.findUnique.mockResolvedValue(null);
    p.user.create.mockResolvedValue(mockUser({ email: "new@umira.app" }));
    p.auditLog.create.mockResolvedValue({});

    const res = await app.inject({
      method: "POST",
      url: "/v1/auth/signup",
      payload: { email: "new@umira.app", password: "StrongPass1!" },
    });

    expect(res.statusCode).toBe(201);
    const body = JSON.parse(res.body);
    expect(body.token).toBeTruthy();
    expect(body.user.email).toBe("new@umira.app");
  });

  it("returns 409 when email already exists", async () => {
    const p = await getPrisma() as any;
    p.user.findUnique.mockResolvedValue(mockUser());

    const res = await app.inject({
      method: "POST",
      url: "/v1/auth/signup",
      payload: { email: "existing@umira.app", password: "StrongPass1!" },
    });

    expect(res.statusCode).toBe(409);
    expect(JSON.parse(res.body).error).toBe("email_taken");
  });

  it("returns 400 for invalid email", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/auth/signup",
      payload: { email: "notanemail", password: "StrongPass1!" },
    });
    expect(res.statusCode).toBe(400);
  });

  it("returns 400 for short password", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/auth/signup",
      payload: { email: "test@umira.app", password: "123" },
    });
    expect(res.statusCode).toBe(400);
  });
});

// ══════════════════════════════════════════════
// POST /v1/auth/signin
// ══════════════════════════════════════════════

describe("POST /v1/auth/signin", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns 200 with JWT for valid credentials", async () => {
    const p = await getPrisma() as any;
    p.user.findUnique.mockResolvedValue(mockUser());
    p.auditLog.create.mockResolvedValue({});

    const res = await app.inject({
      method: "POST",
      url: "/v1/auth/signin",
      payload: { email: "test@umira.app", password: "StrongPass1!" },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.token).toBeTruthy();
    expect(body.user.email).toBe("test@umira.app");
  });

  it("returns 401 for non-existent user", async () => {
    const p = await getPrisma() as any;
    p.user.findUnique.mockResolvedValue(null);

    const res = await app.inject({
      method: "POST",
      url: "/v1/auth/signin",
      payload: { email: "nobody@umira.app", password: "StrongPass1!" },
    });
    expect(res.statusCode).toBe(401);
  });

  it("returns 401 for deleted user", async () => {
    const p = await getPrisma() as any;
    p.user.findUnique.mockResolvedValue(mockUser({ deletedAt: new Date() }));

    const res = await app.inject({
      method: "POST",
      url: "/v1/auth/signin",
      payload: { email: "deleted@umira.app", password: "StrongPass1!" },
    });
    expect(res.statusCode).toBe(401);
  });
});

// ══════════════════════════════════════════════
// GET /v1/me
// ══════════════════════════════════════════════

describe("GET /v1/me", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns the current user profile", async () => {
    const p = await getPrisma() as any;
    p.user.findUnique.mockResolvedValue(mockUser());

    const headers = injectAuth(app);
    const res = await app.inject({
      method: "GET",
      url: "/v1/me",
      headers,
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.user.email).toBe("test@umira.app");
  });

  it("returns 401 without auth token", async () => {
    const res = await app.inject({ method: "GET", url: "/v1/me" });
    expect(res.statusCode).toBe(401);
  });
});
