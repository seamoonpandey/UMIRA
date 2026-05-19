import { prisma } from "../../db/prisma.js";
import { generateMicrotasks } from "../../ai/orchestrator.js";
import { audit } from "../../utils/audit.js";
import { assertTaskOwner } from "../../utils/ownership.js";
import { badRequest, notFound } from "../../utils/errors.js";

export async function listTasks(userId: string, status?: string) {
  return prisma.task.findMany({
    where: { userId, status: status ?? undefined, archivedAt: null },
    include: { microtasks: { orderBy: { position: "asc" } } },
    orderBy: { createdAt: "desc" },
    take: 200,
  });
}

export async function createTask(userId: string, data: { title: string; sourceText?: string; priority?: string; dueAt?: string }) {
  const t = await prisma.task.create({
    data: {
      userId,
      title: data.title,
      sourceText: data.sourceText,
      priority: data.priority ?? "normal",
      dueAt: data.dueAt ? new Date(data.dueAt) : null,
    },
  });
  await audit(userId, "task.create", "task", t.id);
  return t;
}

export async function generateAndAttachMicrotasks(userId: string, taskId: string, goal: string, context?: string, sessionLength?: number, extraSimplify?: boolean) {
  await assertTaskOwner(taskId, userId);
  const result = await generateMicrotasks({ userId, goal, context, sessionLength, extraSimplify });
  if (!result.ok) return result;
  // Replace existing AI-generated microtasks that are still pending
  await prisma.microtask.deleteMany({ where: { taskId, generatedBy: "ai", status: "pending" } });
  await prisma.microtask.createMany({
    data: result.steps.map((s, idx) => ({
      taskId,
      label: s.label,
      position: idx,
      estimatedMinutes: s.estimated_minutes,
      generatedBy: "ai",
    })),
  });
  await audit(userId, "task.microtasks_generated", "task", taskId, { count: result.steps.length });
  const tasks = await prisma.microtask.findMany({ where: { taskId }, orderBy: { position: "asc" } });
  return { ok: true as const, microtasks: tasks };
}

export async function updateTask(userId: string, taskId: string, data: { title?: string; status?: string; priority?: string; dueAt?: string | null }) {
  await assertTaskOwner(taskId, userId);
  const t = await prisma.task.update({
    where: { id: taskId },
    data: {
      ...data,
      dueAt: data.dueAt === undefined ? undefined : data.dueAt === null ? null : new Date(data.dueAt),
      archivedAt: data.status === "archived" ? new Date() : undefined,
    },
  });
  await audit(userId, "task.update", "task", taskId, { fields: Object.keys(data) });
  return t;
}

export async function deleteTask(userId: string, taskId: string) {
  await assertTaskOwner(taskId, userId);
  await prisma.task.delete({ where: { id: taskId } });
  await audit(userId, "task.delete", "task", taskId);
}

export async function updateMicrotask(userId: string, microId: string, data: { label?: string; status?: string; position?: number; estimatedMinutes?: number }) {
  const mt = await prisma.microtask.findUnique({ where: { id: microId }, include: { task: { select: { userId: true } } } });
  if (!mt) throw notFound("microtask");
  if (mt.task.userId !== userId) throw notFound("microtask");
  const updated = await prisma.microtask.update({
    where: { id: microId },
    data: { ...data, editedByUser: true },
  });
  await audit(userId, "microtask.update", "microtask", microId);
  return updated;
}

export async function reorderMicrotasks(userId: string, taskId: string, orderedIds: string[]) {
  await assertTaskOwner(taskId, userId);
  const existing = await prisma.microtask.findMany({ where: { taskId } });
  const known = new Set(existing.map((m) => m.id));
  for (const id of orderedIds) if (!known.has(id)) throw badRequest("unknown microtask id");
  await prisma.$transaction(orderedIds.map((id, idx) => prisma.microtask.update({ where: { id }, data: { position: idx, editedByUser: true } })));
  await audit(userId, "microtask.reorder", "task", taskId);
  return prisma.microtask.findMany({ where: { taskId }, orderBy: { position: "asc" } });
}
