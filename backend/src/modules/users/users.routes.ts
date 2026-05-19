import type { FastifyInstance } from "fastify";
import { SignIn, SignUp } from "./users.schemas.js";
import { authenticateUser, createUser } from "./users.service.js";
import { authenticate } from "../../auth/middleware.js";
import { prisma } from "../../db/prisma.js";
import { registeredUsers } from "../../config/metrics.js";

export default async function userRoutes(app: FastifyInstance) {
  app.post("/auth/signup", async (req, reply) => {
    const body = SignUp.parse(req.body);
    const user = await createUser(body);
    const token = app.jwt.sign({ id: user.id, email: user.email, tier: user.tier });
    registeredUsers?.inc();
    return reply.code(201).send({ token, user: { id: user.id, email: user.email } });
  });

  app.post("/auth/signin", async (req, reply) => {
    const body = SignIn.parse(req.body);
    const user = await authenticateUser(body);
    const token = app.jwt.sign({ id: user.id, email: user.email, tier: user.tier });
    return reply.send({ token, user: { id: user.id, email: user.email } });
  });

  app.get("/me", { preHandler: authenticate }, async (req) => {
    const u = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true, email: true, locale: true, timezone: true, tier: true,
        createdAt: true, marketingOptIn: true, consentVersion: true,
      },
    });
    return { user: u };
  });
}
