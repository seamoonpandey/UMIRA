import { prisma } from "../db/prisma.js";
import type { Prisma } from "@prisma/client";

export async function audit(
  userId: string | null,
  action: string,
  entityType: string,
  entityId?: string | null,
  metadata?: Record<string, unknown>,
) {
  await prisma.auditLog.create({
    data: {
      userId: userId ?? undefined,
      action,
      entityType,
      entityId: entityId ?? undefined,
      metadataJson: (metadata ?? undefined) as Prisma.InputJsonValue | undefined,
    },
  });
}
