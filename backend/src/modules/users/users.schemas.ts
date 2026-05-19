import { z } from "zod";

export const SignUp = z.object({
  email: z.string().email().max(254),
  password: z.string().min(8).max(128),
  locale: z.string().max(10).optional(),
  timezone: z.string().max(64).optional(),
  consentVersion: z.string().max(10).optional(),
  marketingOptIn: z.boolean().optional(),
});

export const SignIn = z.object({
  email: z.string().email().max(254),
  password: z.string().min(1).max(128),
});
