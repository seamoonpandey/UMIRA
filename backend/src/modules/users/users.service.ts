import { prisma } from "../../db/prisma.js";
import { hashPassword, verifyPassword } from "../../auth/hash.js";
import { HttpError } from "../../utils/errors.js";
import { audit } from "../../utils/audit.js";
import { z } from "zod";
import { SignIn, SignUp } from "./users.schemas.js";

export async function createUser(input: z.infer<typeof SignUp>) {
  const existing = await prisma.user.findUnique({ where: { email: input.email.toLowerCase() } });
  if (existing) throw new HttpError(409, "email_taken", "conflict");
  const passwordHash = await hashPassword(input.password);
  const user = await prisma.user.create({
    data: {
      email: input.email.toLowerCase(),
      passwordHash,
      locale: input.locale ?? "en",
      timezone: input.timezone ?? "UTC",
      consentVersion: input.consentVersion ?? "1.0",
      marketingOptIn: input.marketingOptIn ?? false,
      preferences: { create: {} },
    },
  });
  await audit(user.id, "user.signup", "user", user.id);
  return user;
}

export async function authenticateUser(input: z.infer<typeof SignIn>) {
  const user = await prisma.user.findUnique({ where: { email: input.email.toLowerCase() } });
  if (!user || user.deletedAt) throw new HttpError(401, "invalid_credentials");
  const ok = await verifyPassword(user.passwordHash, input.password);
  if (!ok) throw new HttpError(401, "invalid_credentials");
  await audit(user.id, "user.signin", "user", user.id);
  return user;
}
