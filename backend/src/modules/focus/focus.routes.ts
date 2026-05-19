import type { FastifyInstance } from "fastify";
import { authenticate } from "../../auth/middleware.js";
import { CancelFocus, CompleteFocus, StartFocus } from "./focus.schemas.js";
import { cancelFocus, completeFocus, listFocus, startFocus } from "./focus.service.js";
import { z } from "zod";

export default async function focusRoutes(app: FastifyInstance) {
  app.addHook("preHandler", authenticate);

  app.get("/focus/sessions", async (req) => ({ sessions: await listFocus(req.user.id) }));

  app.post("/focus/sessions", async (req, reply) => {
    const body = StartFocus.parse(req.body);
    const s = await startFocus(req.user.id, body.taskId, body.plannedMinutes);
    return reply.code(201).send({ session: s });
  });

  app.post("/focus/sessions/:id/complete", async (req) => {
    const { id } = z.object({ id: z.string().cuid() }).parse(req.params);
    const body = CompleteFocus.parse(req.body);
    return completeFocus(req.user.id, id, body);
  });

  app.post("/focus/sessions/:id/cancel", async (req) => {
    const { id } = z.object({ id: z.string().cuid() }).parse(req.params);
    CancelFocus.parse(req.body ?? {});
    return { session: await cancelFocus(req.user.id, id) };
  });
}
