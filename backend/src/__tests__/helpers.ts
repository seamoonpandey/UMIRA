import { buildApp } from "../app";
import type { FastifyInstance } from "fastify";
import { vi } from "vitest";

// ══════════════════════════════════════════════
// App factory — creates a fresh Fastify instance
// ══════════════════════════════════════════════

let _app: FastifyInstance | null = null;

export async function getApp(): Promise<FastifyInstance> {
  if (!_app) {
    _app = await buildApp();
    await _app.ready();
  }
  return _app;
}

export async function closeApp(): Promise<void> {
  if (_app) {
    await _app.close();
    _app = null;
  }
}

// ══════════════════════════════════════════════
// JWT token generator for authenticated routes
// ══════════════════════════════════════════════

export function injectAuth(
  app: FastifyInstance,
  userId = "test_user_id",
  email = "test@umira.app",
  tier = "free",
) {
  const token = app.jwt.sign({ id: userId, email, tier });
  return { authorization: `Bearer ${token}` };
}

// ══════════════════════════════════════════════
// Mock data factories
// ══════════════════════════════════════════════

export const mockUser = (overrides: Record<string, unknown> = {}) => ({
  id: "test_user_id",
  email: "test@umira.app",
  passwordHash: "$argon2id$v=19$m=65536,t=3,p=4$hashed_password_here",
  locale: "en",
  timezone: "UTC",
  consentVersion: "1.0",
  marketingOptIn: false,
  tier: "free",
  createdAt: new Date("2024-01-01"),
  updatedAt: new Date("2024-01-01"),
  deletedAt: null,
  ...overrides,
});

export const mockTask = (overrides: Record<string, unknown> = {}) => ({
  id: "task_test_id",
  userId: "test_user_id",
  title: "Test task",
  sourceText: null,
  status: "open",
  priority: "normal",
  dueAt: null,
  createdAt: new Date("2024-01-01"),
  archivedAt: null,
  microtasks: [],
  ...overrides,
});

export const mockPreferences = (overrides: Record<string, unknown> = {}) => ({
  id: "pref_test_id",
  userId: "test_user_id",
  textDensity: "comfortable",
  lineFocus: false,
  fontScale: 1.0,
  spacingMode: "normal",
  sessionLengthDefault: 15,
  cueIntensity: "gentle",
  rewardStyle: "minimal",
  simplifyLevel: "medium",
  useDyslexiaFont: false,
  reducedMotion: false,
  ttsRate: 1.0,
  ttsPitch: 1.0,
  updatedAt: new Date("2024-01-01"),
  ...overrides,
});
