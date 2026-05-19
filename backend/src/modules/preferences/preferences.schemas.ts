import { z } from "zod";

export const UpdatePrefs = z.object({
  textDensity: z.enum(["compact", "comfortable", "spacious"]).optional(),
  lineFocus: z.boolean().optional(),
  fontScale: z.number().min(0.8).max(2.0).optional(),
  spacingMode: z.enum(["normal", "wide", "extra-wide"]).optional(),
  sessionLengthDefault: z.number().int().min(5).max(60).optional(),
  cueIntensity: z.enum(["off", "gentle", "strong"]).optional(),
  rewardStyle: z.enum(["none", "minimal", "celebratory"]).optional(),
  simplifyLevel: z.enum(["light", "medium", "high"]).optional(),
  useDyslexiaFont: z.boolean().optional(),
  reducedMotion: z.boolean().optional(),
  ttsRate: z.number().min(0.5).max(2.0).optional(),
  ttsPitch: z.number().min(0.5).max(2.0).optional(),
});
