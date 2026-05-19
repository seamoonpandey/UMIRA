import type { FastifyInstance } from "fastify";
import { authenticate } from "../../auth/middleware.js";
import { TrackEvent } from "./analytics.schemas.js";
import { summary, trackEvent } from "./analytics.service.js";

export default async function analyticsRoutes(app: FastifyInstance) {
  app.addHook("preHandler", authenticate);

  app.post("/analytics/events", async (req, reply) => {
    const body = TrackEvent.parse(req.body);
    await trackEvent(req.user.id, body.eventName, body.props ?? {});
    return reply.code(204).send();
  });

  app.get("/analytics/summary", async (req) => summary(req.user.id));
}
