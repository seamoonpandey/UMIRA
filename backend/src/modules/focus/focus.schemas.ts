import { z } from "zod";

export const StartFocus = z.object({
  taskId: z.string().cuid().optional(),
  plannedMinutes: z.number().int().min(5).max(60),
});

export const CompleteFocus = z.object({
  actualMinutes: z.number().int().min(0).max(120),
  distractionEvents: z.number().int().min(0).max(200).optional(),
  reflectionText: z.string().max(1000).optional(),
  generateAiReflection: z.boolean().optional(),
});

export const CancelFocus = z.object({});
