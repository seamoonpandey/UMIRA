import { z } from "zod";

export const SimplifyRequest = z.object({
  text: z.string().min(20).max(20_000),
  level: z.enum(["light", "medium", "high"]).optional(),
  glossary: z.boolean().optional(),
  save: z.boolean().optional(),
  ttsEnabled: z.boolean().optional(),
});
