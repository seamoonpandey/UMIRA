import { z } from "zod";

const VERB_RE = /^[A-Z][a-zA-Z-]+(\s|$)/;

export const MicrotaskOutput = z.object({
  steps: z
    .array(
      z.object({
        label: z.string().min(2).max(120),
        estimated_minutes: z.number().int().min(1).max(60),
      }),
    )
    .max(12),
  refusal: z.string().nullable().optional(),
});

export function validateMicrotaskSteps(parsed: z.infer<typeof MicrotaskOutput>) {
  if (parsed.refusal) return { ok: true as const, refusal: parsed.refusal, steps: [] };
  if (parsed.steps.length < 3)
    return { ok: false as const, reason: "Too few steps (<3)." };
  for (const s of parsed.steps) {
    if (s.label.length > 120) return { ok: false as const, reason: "Step too long" };
    if (!VERB_RE.test(s.label.trim()))
      return { ok: false as const, reason: `Step must start with a verb: "${s.label}"` };
  }
  return { ok: true as const, refusal: null, steps: parsed.steps };
}

export const SimplifyOutput = z.object({
  summary: z.string().min(10).max(800),
  chunks: z
    .array(
      z.object({
        original: z.string().min(1),
        simplified: z.string().min(1),
      }),
    )
    .min(1)
    .max(40),
  key_terms: z
    .array(z.object({ term: z.string().min(1), definition: z.string().min(1) }))
    .max(40)
    .default([]),
});

export function validateGrounding(original: string, simplified: string) {
  const tokens = simplified.match(/\b([A-Z][a-zA-Z0-9.-]{2,}|\d[\d.,]*)\b/g) ?? [];
  const allowed = new Set([
    "I","A","The","And","Or","But","If","When","While","Step","Tip","Note","You","Your",
  ]);
  const orig = original;
  for (const tok of tokens) {
    if (allowed.has(tok)) continue;
    if (!orig.includes(tok)) {
      return { ok: false as const, reason: `Unverified token introduced: "${tok}"` };
    }
  }
  return { ok: true as const };
}

export const ReflectionOutput = z.object({ reflection: z.string().min(2).max(280) });
