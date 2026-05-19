import type { FastifyReply, FastifyRequest } from "fastify";
import { prisma } from "../db/prisma.js";

export async function authenticate(req: FastifyRequest, reply: FastifyReply) {
  try {
    await req.jwtVerify();
  } catch {
    return reply.code(401).send({ error: "unauthorized" });
  }

  // Verify user still exists and is not soft-deleted
  const user = await prisma.user.findUnique({
    where: { id: req.user.id },
    select: { id: true, email: true, tier: true, deletedAt: true },
  });

  if (!user || user.deletedAt) {
    return reply.code(401).send({ error: "unauthorized" });
  }

  // Attach tier to the request for downstream use (rate limiting, feature gating)
  req.user = { id: user.id, email: user.email, tier: user.tier };
}

declare module "fastify" {
  interface FastifyRequest {
    user: { id: string; email: string; tier: string };
  }
}

declare module "@fastify/jwt" {
  interface FastifyJWT {
    payload: { id: string; email: string; tier: string };
    user: { id: string; email: string; tier: string };
  }
}
