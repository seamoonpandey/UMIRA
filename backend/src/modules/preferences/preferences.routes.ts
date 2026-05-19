import type { FastifyInstance } from "fastify";
import { authenticate } from "../../auth/middleware.js";
import { UpdatePrefs } from "./preferences.schemas.js";
import { getPrefs, updatePrefs } from "./preferences.service.js";

export default async function preferencesRoutes(app: FastifyInstance) {
  app.get("/preferences", { preHandler: authenticate }, async (req) => {
    return { preferences: await getPrefs(req.user.id) };
  });
  app.patch("/preferences", { preHandler: authenticate }, async (req) => {
    const body = UpdatePrefs.parse(req.body);
    return { preferences: await updatePrefs(req.user.id, body) };
  });
}
