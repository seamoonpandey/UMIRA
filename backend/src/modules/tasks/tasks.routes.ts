import type { FastifyInstance } from "fastify";
import { authenticate } from "../../auth/middleware.js";
import {
  CreateTask, GenerateMicrotasks, ReorderMicrotasks, UpdateMicrotask, UpdateTask,
} from "./tasks.schemas.js";
import {
  createTask, deleteTask, generateAndAttachMicrotasks, listTasks,
  reorderMicrotasks, updateMicrotask, updateTask,
} from "./tasks.service.js";
import { z } from "zod";

export default async function taskRoutes(app: FastifyInstance) {
  app.addHook("preHandler", authenticate);

  app.get("/tasks", async (req) => {
    const q = z.object({ status: z.string().optional() }).parse(req.query);
    return { tasks: await listTasks(req.user.id, q.status) };
  });

  app.post("/tasks", async (req, reply) => {
    const body = CreateTask.parse(req.body);
    const t = await createTask(req.user.id, body);
    return reply.code(201).send({ task: t });
  });

  app.patch("/tasks/:id", async (req) => {
    const { id } = z.object({ id: z.string().cuid() }).parse(req.params);
    const body = UpdateTask.parse(req.body);
    return { task: await updateTask(req.user.id, id, body) };
  });

  app.delete("/tasks/:id", async (req, reply) => {
    const { id } = z.object({ id: z.string().cuid() }).parse(req.params);
    await deleteTask(req.user.id, id);
    return reply.code(204).send();
  });

  app.post("/tasks/:id/microtasks/generate", async (req) => {
    const { id } = z.object({ id: z.string().cuid() }).parse(req.params);
    const body = GenerateMicrotasks.parse(req.body);
    const result = await generateAndAttachMicrotasks(
      req.user.id, id, body.goal, body.context, body.sessionLength, body.extraSimplify,
    );
    return result;
  });

  app.patch("/microtasks/:id", async (req) => {
    const { id } = z.object({ id: z.string().cuid() }).parse(req.params);
    const body = UpdateMicrotask.parse(req.body);
    return { microtask: await updateMicrotask(req.user.id, id, body) };
  });

  app.post("/tasks/:id/microtasks/reorder", async (req) => {
    const { id } = z.object({ id: z.string().cuid() }).parse(req.params);
    const body = ReorderMicrotasks.parse(req.body);
    return { microtasks: await reorderMicrotasks(req.user.id, id, body.orderedIds) };
  });
}
