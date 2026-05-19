import { prisma } from "../../db/prisma.js";
import { audit } from "../../utils/audit.js";
import type { z } from "zod";
import type { UpdatePrefs } from "./preferences.schemas.js";

export async function getPrefs(userId: string) {
  let p = await prisma.userPreference.findUnique({ where: { userId } });
  if (!p) p = await prisma.userPreference.create({ data: { userId } });
  return p;
}

export async function updatePrefs(userId: string, data: z.infer<typeof UpdatePrefs>) {
  const updated = await prisma.userPreference.upsert({
    where: { userId },
    update: data,
    create: { userId, ...data },
  });
  await audit(userId, "preferences.update", "user_preference", updated.id, { fields: Object.keys(data) });
  return updated;
}
