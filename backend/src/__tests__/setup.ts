import { vi } from "vitest";

// ══════════════════════════════════════════════
// Test environment — runs before all test files
// ══════════════════════════════════════════════

process.env.NODE_ENV = "test";
process.env.DATABASE_URL = "postgresql://test:test@localhost:5432/test?schema=public";
process.env.JWT_SECRET = "this_is_a_test_secret_that_is_long_enough_32_chars";
process.env.JWT_EXPIRES_IN = "1h";
process.env.AI_PROVIDER = "mock";
process.env.LOG_LEVEL = "silent";
process.env.CORS_ORIGINS = "http://localhost:8080";
process.env.RATE_LIMIT_MAX = "1000";
process.env.RATE_LIMIT_WINDOW = "60000";

// ══════════════════════════════════════════════
// Prisma mock — all models return vi.fn() stubs
// ══════════════════════════════════════════════

function mockModel() {
  return {
    findUnique: vi.fn(),
    findMany: vi.fn(),
    findFirst: vi.fn(),
    create: vi.fn(),
    update: vi.fn(),
    delete: vi.fn(),
    deleteMany: vi.fn(),
    createMany: vi.fn(),
    count: vi.fn(),
    upsert: vi.fn(),
    aggregate: vi.fn(),
  };
}

vi.mock("../db/prisma.js", () => ({
  prisma: {
    user: mockModel(),
    userPreference: mockModel(),
    task: mockModel(),
    microtask: mockModel(),
    textSession: mockModel(),
    textChunk: mockModel(),
    focusSession: mockModel(),
    analyticsEvent: mockModel(),
    aiJob: mockModel(),
    auditLog: mockModel(),
    $disconnect: vi.fn(),
    $transaction: vi.fn((cb: (tx: Record<string, any>) => any) =>
      cb({
        microtask: {
          update: vi.fn(),
          findMany: vi.fn(),
        },
      }),
    ),
  },
}));
