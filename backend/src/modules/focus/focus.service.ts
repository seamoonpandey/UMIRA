import { prisma } from "../../db/prisma.js";
import { generateReflection } from "../../ai/orchestrator.js";
import { audit } from "../../utils/audit.js";
import { assertFocusOwner } from "../../utils/ownership.js";
import { badRequest } from "../../utils/errors.js";

export async function startFocus(userId: string, taskId: string | undefined, plannedMinutes: number) {
  const s = await prisma.focusSession.create({
    data: {
      userId,
      taskId,
      plannedMinutes,
      status: "running",
      startedAt: new Date(),
    },
  });
  await audit(userId, "focus.start", "focus_session", s.id, { plannedMinutes });
  return s;
}

export async function completeFocus(userId: string, id: string, data: {
  actualMinutes: number;
  distractionEvents?: number;
  reflectionText?: string;
  generateAiReflection?: boolean;
}) {
  await assertFocusOwner(id, userId);
  const session = await prisma.focusSession.findUnique({ where: { id }, include: { task: true } });
  if (!session) throw badRequest("session not found");
  let aiReflection: string | undefined;
  if (data.generateAiReflection) {
    try {
      const r = await generateReflection({
        userId, taskTitle: session.task?.title, minutes: data.actualMinutes,
      });
      aiReflection = r.reflection;
    } catch {
      aiReflection = undefined;
    }
  }
  const completed = await prisma.focusSession.update({
    where: { id },
    data: {
      status: "completed",
      actualMinutes: data.actualMinutes,
      distractionEvents: data.distractionEvents ?? 0,
      reflectionText: data.reflectionText ?? aiReflection ?? null,
      completedAt: new Date(),
    },
  });
  await audit(userId, "focus.complete", "focus_session", id, {
    actualMinutes: data.actualMinutes,
  });
  return { session: completed, aiReflection: aiReflection ?? null };
}

export async function cancelFocus(userId: string, id: string) {
  await assertFocusOwner(id, userId);
  const s = await prisma.focusSession.update({
    where: { id },
    data: { status: "cancelled", completedAt: new Date() },
  });
  await audit(userId, "focus.cancel", "focus_session", id);
  return s;
}

export async function listFocus(userId: string) {
  return prisma.focusSession.findMany({
    where: { userId },
    orderBy: { createdAt: "desc" },
    take: 100,
  });
}
