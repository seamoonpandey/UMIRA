import { prisma } from "../../db/prisma.js";

export async function trackEvent(userId: string, eventName: string, props: Record<string, unknown> = {}) {
  return prisma.analyticsEvent.create({
    data: { userId, eventName, eventProps: props as object },
  });
}

export async function summary(userId: string) {
  const sinceDate = new Date(Date.now() - 30 * 24 * 3600 * 1000);
  const [tasksCreated, microtasksDone, focusCompleted, focusMinutes, readingSessions] = await Promise.all([
    prisma.task.count({ where: { userId, createdAt: { gte: sinceDate } } }),
    prisma.microtask.count({
      where: { task: { userId }, status: "done", createdAt: { gte: sinceDate } },
    }),
    prisma.focusSession.count({
      where: { userId, status: "completed", completedAt: { gte: sinceDate } },
    }),
    prisma.focusSession.aggregate({
      _sum: { actualMinutes: true },
      where: { userId, status: "completed", completedAt: { gte: sinceDate } },
    }),
    prisma.textSession.count({ where: { userId, createdAt: { gte: sinceDate } } }),
  ]);

  // Avg planned vs actual for time-estimation feedback
  const focusComparison = await prisma.focusSession.findMany({
    where: { userId, status: "completed", completedAt: { gte: sinceDate } },
    select: { plannedMinutes: true, actualMinutes: true },
  });
  const avgPlanned =
    focusComparison.length ? focusComparison.reduce((a, b) => a + b.plannedMinutes, 0) / focusComparison.length : 0;
  const avgActual =
    focusComparison.length
      ? focusComparison.reduce((a, b) => a + (b.actualMinutes ?? 0), 0) / focusComparison.length
      : 0;

  return {
    window_days: 30,
    tasks_created: tasksCreated,
    microtasks_done: microtasksDone,
    focus_completed: focusCompleted,
    focus_total_minutes: focusMinutes._sum.actualMinutes ?? 0,
    reading_sessions: readingSessions,
    estimation_accuracy: {
      avg_planned_minutes: Math.round(avgPlanned * 10) / 10,
      avg_actual_minutes: Math.round(avgActual * 10) / 10,
    },
  };
}
