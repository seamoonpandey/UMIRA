import { z } from "zod";

export const AnalyzePractice = z.object({
  expectedText: z.string().min(1).max(2000).default("The boy went to the store to buy some candy."),
});

export const SavePracticeResult = z.object({
  wordData: z.array(z.record(z.any())),
  stats: z.object({
    wpm: z.number(),
    skippedWords: z.number(),
    repetitions: z.number(),
  }),
  expectedText: z.string(),
  sessionType: z.enum(["practice", "spelling", "typing", "lesson"]).default("practice"),
  score: z.number().optional(),
  total: z.number().optional(),
});

export const SaveInterventionSession = z.object({
  type: z.enum(["spelling", "typing", "lesson", "practice"]),
  score: z.number().optional(),
  total: z.number().optional(),
  wpm: z.number().optional(),
  accuracy: z.number().optional(),
  grapheme: z.string().optional(),
  phoneme: z.string().optional(),
  stats: z.record(z.any()).optional(),
});

export const OcrRequest = z.object({
  // handled via multipart form
});
