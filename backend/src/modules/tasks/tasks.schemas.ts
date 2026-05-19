import { z } from "zod";

export const CreateTask = z.object({
  title: z.string().min(1).max(280),
  sourceText: z.string().max(8000).optional(),
  priority: z.enum(["low", "normal", "high"]).optional(),
  dueAt: z.string().datetime().optional(),
});

export const GenerateMicrotasks = z.object({
  goal: z.string().min(2).max(500),
  context: z.string().max(2000).optional(),
  sessionLength: z.number().int().min(5).max(60).optional(),
  extraSimplify: z.boolean().optional(),
});

export const UpdateTask = z.object({
  title: z.string().min(1).max(280).optional(),
  status: z.enum(["open", "in_progress", "done", "archived"]).optional(),
  priority: z.enum(["low", "normal", "high"]).optional(),
  dueAt: z.string().datetime().nullable().optional(),
});

export const UpdateMicrotask = z.object({
  label: z.string().min(1).max(120).optional(),
  status: z.enum(["pending", "done", "skipped"]).optional(),
  position: z.number().int().min(0).optional(),
  estimatedMinutes: z.number().int().min(1).max(60).optional(),
});

export const ReorderMicrotasks = z.object({
  orderedIds: z.array(z.string().cuid()).min(1).max(50),
});
