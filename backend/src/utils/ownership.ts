import { prisma } from "../db/prisma.js";
import { forbidden, notFound } from "./errors.js";

export async function assertTaskOwner(taskId: string, userId: string) {
  const t = await prisma.task.findUnique({ where: { id: taskId }, select: { userId: true } });
  if (!t) throw notFound("task");
  if (t.userId !== userId) throw forbidden();
}

export async function assertTextSessionOwner(id: string, userId: string) {
  const t = await prisma.textSession.findUnique({ where: { id }, select: { userId: true } });
  if (!t) throw notFound("text_session");
  if (t.userId !== userId) throw forbidden();
}

export async function assertFocusOwner(id: string, userId: string) {
  const t = await prisma.focusSession.findUnique({ where: { id }, select: { userId: true } });
  if (!t) throw notFound("focus_session");
  if (t.userId !== userId) throw forbidden();
}
