import { prisma } from "../../db/prisma.js";
import { audit } from "../../utils/audit.js";

export async function exportUserData(userId: string) {
  const [user, preferences, tasks, textSessions, focusSessions, analyticsEvents, aiJobs] = await Promise.all([
    prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, email: true, locale: true, timezone: true, createdAt: true, marketingOptIn: true, consentVersion: true },
    }),
    prisma.userPreference.findUnique({ where: { userId } }),
    prisma.task.findMany({ where: { userId }, include: { microtasks: true } }),
    prisma.textSession.findMany({ where: { userId }, include: { chunks: true } }),
    prisma.focusSession.findMany({ where: { userId } }),
    prisma.analyticsEvent.findMany({ where: { userId } }),
    prisma.aiJob.findMany({ where: { userId } }),
  ]);
  await audit(userId, "privacy.export", "user", userId);
  return {
    exported_at: new Date().toISOString(),
    user, preferences, tasks, textSessions, focusSessions, analyticsEvents, aiJobs,
  };
}

export async function hardDeleteUser(userId: string) {
  // cascading deletes via Prisma relations
  await prisma.user.delete({ where: { id: userId } });
  await audit(null, "privacy.hard_delete", "user", userId);
}
