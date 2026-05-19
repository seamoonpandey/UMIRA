import type { FastifyInstance } from "fastify";
import { authenticate } from "../../auth/middleware.js";
import { exportUserData, hardDeleteUser } from "./privacy.service.js";

export default async function privacyRoutes(app: FastifyInstance) {
  app.addHook("preHandler", authenticate);

  app.get("/privacy/export", async (req, reply) => {
    const data = await exportUserData(req.user.id);
    reply.header("content-type", "application/json");
    reply.header("content-disposition", `attachment; filename="umira-export-${req.user.id}.json"`);
    return data;
  });

  app.delete("/privacy/account", async (req, reply) => {
    await hardDeleteUser(req.user.id);
    return reply.code(204).send();
  });
}
