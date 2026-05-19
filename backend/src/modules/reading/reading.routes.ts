import type { FastifyInstance } from "fastify";
import { authenticate } from "../../auth/middleware.js";
import { SimplifyRequest } from "./reading.schemas.js";
import { deleteSession, getSession, listSessions, simplifyAndOptionallySave } from "./reading.service.js";
import { z } from "zod";

export default async function readingRoutes(app: FastifyInstance) {
  app.addHook("preHandler", authenticate);

  app.post("/reading/simplify", async (req) => {
    const body = SimplifyRequest.parse(req.body);
    return simplifyAndOptionallySave({ userId: req.user.id, ...body });
  });

  app.get("/reading/sessions", async (req) => ({ sessions: await listSessions(req.user.id) }));

  app.get("/reading/sessions/:id", async (req) => {
    const { id } = z.object({ id: z.string().cuid() }).parse(req.params);
    return { session: await getSession(req.user.id, id) };
  });

  app.delete("/reading/sessions/:id", async (req, reply) => {
    const { id } = z.object({ id: z.string().cuid() }).parse(req.params);
    await deleteSession(req.user.id, id);
    return reply.code(204).send();
  });
}
