import crypto from "node:crypto";
import { prisma } from "../db/prisma.js";
import { getProvider } from "./provider.js";
import { MICROTASK_SYSTEM, REFLECTION_SYSTEM, SIMPLIFY_SYSTEM } from "./prompts.js";
import {
  MicrotaskOutput,
  ReflectionOutput,
  SimplifyOutput,
  validateGrounding,
  validateMicrotaskSteps,
} from "./validators.js";

const hash = (s: string) => crypto.createHash("sha256").update(s).digest("hex");

const UNSAFE_RE = /\b(suicide|self[-\s]?harm|kill myself|hurt myself|overdose)\b/i;

export async function generateMicrotasks(opts: {
  userId: string;
  goal: string;
  context?: string;
  sessionLength?: number;
  extraSimplify?: boolean;
}) {
  if (UNSAFE_RE.test(opts.goal)) {
    return {
      ok: false as const,
      refusal:
        "I cannot help with this request. If you are in crisis, please reach out to a trusted person or local emergency services.",
      steps: [],
    };
  }
  const provider = await getProvider();
  const userPrompt = `Goal: ${opts.goal}
Context: ${opts.context ?? "(none)"}
Preferred session length (minutes): ${opts.sessionLength ?? 15}
Need extra simplification: ${opts.extraSimplify ? "yes" : "no"}`;
  const inputHash = hash(userPrompt);
  const job = await prisma.aiJob.create({
    data: { userId: opts.userId, jobType: "microtask_generate", inputHash, modelClass: provider.name() },
  });
  try {
    const raw = await provider.chatJson({
      messages: [
        { role: "system", content: MICROTASK_SYSTEM },
        { role: "user", content: userPrompt },
      ],
      temperature: 0.3,
      maxTokens: 800,
    });
    const parsed = MicrotaskOutput.parse(raw);
    const v = validateMicrotaskSteps(parsed);
    if (!v.ok) {
      await prisma.aiJob.update({
        where: { id: job.id },
        data: { validatorStatus: "rejected", errorMessage: v.reason },
      });
      return { ok: false as const, refusal: null, steps: [], error: v.reason };
    }
    if (v.refusal) {
      await prisma.aiJob.update({ where: { id: job.id }, data: { validatorStatus: "passed" } });
      return { ok: false as const, refusal: v.refusal, steps: [] };
    }
    await prisma.aiJob.update({
      where: { id: job.id },
      data: { validatorStatus: "passed", outputHash: hash(JSON.stringify(v.steps)) },
    });
    return { ok: true as const, refusal: null, steps: v.steps };
  } catch (err) {
    await prisma.aiJob.update({
      where: { id: job.id },
      data: { validatorStatus: "rejected", errorMessage: (err as Error).message },
    });
    throw err;
  }
}

export async function simplifyText(opts: {
  userId: string;
  text: string;
  level?: "light" | "medium" | "high";
  glossary?: boolean;
}) {
  const provider = await getProvider();
  const userPrompt = `Text: ${opts.text}
Reading preference: ${opts.level ?? "medium"}_simplification
Glossary mode: ${opts.glossary ? "on" : "off"}`;
  const inputHash = hash(userPrompt);
  const job = await prisma.aiJob.create({
    data: { userId: opts.userId, jobType: "text_simplify", inputHash, modelClass: provider.name() },
  });
  try {
    const raw = await provider.chatJson({
      messages: [
        { role: "system", content: SIMPLIFY_SYSTEM },
        { role: "user", content: userPrompt },
      ],
      temperature: 0.2,
      maxTokens: 1800,
    });
    const parsed = SimplifyOutput.parse(raw);

    // Grounding check
    const combinedSimplified = parsed.summary + " " + parsed.chunks.map((c) => c.simplified).join(" ");
    const g = validateGrounding(opts.text, combinedSimplified);
    if (!g.ok) {
      await prisma.aiJob.update({
        where: { id: job.id },
        data: { validatorStatus: "rejected", errorMessage: g.reason },
      });
      return { ok: false as const, error: g.reason };
    }

    await prisma.aiJob.update({
      where: { id: job.id },
      data: { validatorStatus: "passed", outputHash: hash(JSON.stringify(parsed)) },
    });
    return { ok: true as const, result: parsed };
  } catch (err) {
    await prisma.aiJob.update({
      where: { id: job.id },
      data: { validatorStatus: "rejected", errorMessage: (err as Error).message },
    });
    throw err;
  }
}

export async function generateReflection(opts: { userId: string; taskTitle?: string; minutes: number }) {
  const provider = await getProvider();
  const userPrompt = `The user just finished a ${opts.minutes}-minute focus session${
    opts.taskTitle ? ` on: ${opts.taskTitle}` : ""
  }. Write a kind reflection.`;
  const raw = await provider.chatJson({
    messages: [
      { role: "system", content: REFLECTION_SYSTEM },
      { role: "user", content: userPrompt },
    ],
    temperature: 0.5,
    maxTokens: 200,
  });
  return ReflectionOutput.parse(raw);
}
