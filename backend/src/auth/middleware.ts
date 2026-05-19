import type { FastifyReply, FastifyRequest } from "fastify";

export async function authenticate(req: FastifyRequest, reply: FastifyReply) {
  try {
    await req.jwtVerify();
  } catch {
    return reply.code(401).send({ error: "unauthorized" });
  }
}

declare module "fastify" {
  interface FastifyRequest {
    user: { id: string; email: string };
  }
}

declare module "@fastify/jwt" {
  interface FastifyJWT {
    payload: { id: string; email: string };
    user: { id: string; email: string };
  }
}
