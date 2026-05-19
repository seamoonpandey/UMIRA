import { prisma } from "../../db/prisma.js";
import { simplifyText } from "../../ai/orchestrator.js";
import { audit } from "../../utils/audit.js";
import { assertTextSessionOwner } from "../../utils/ownership.js";

export async function simplifyAndOptionallySave(opts: {
  userId: string;
  text: string;
  level?: "light" | "medium" | "high";
  glossary?: boolean;
  save?: boolean;
  ttsEnabled?: boolean;
}) {
  const result = await simplifyText({
    userId: opts.userId,
    text: opts.text,
    level: opts.level,
    glossary: opts.glossary,
  });
  if (!result.ok) return result;

  if (opts.save) {
    const session = await prisma.textSession.create({
      data: {
        userId: opts.userId,
        sourceType: "paste",
        originalText: opts.text,
        simplifiedText: result.result.summary,
        readabilityTarget: opts.level ?? "medium",
        ttsEnabled: opts.ttsEnabled ?? false,
        chunks: {
          create: result.result.chunks.map((c, idx) => ({
            chunkIndex: idx,
            originalChunk: c.original,
            simplifiedChunk: c.simplified,
            keyTermsJson: result.result.key_terms,
          })),
        },
      },
      include: { chunks: { orderBy: { chunkIndex: "asc" } } },
    });
    await audit(opts.userId, "reading.session_saved", "text_session", session.id);
    return { ok: true as const, result: result.result, session };
  }
  return { ok: true as const, result: result.result, session: null };
}

export async function listSessions(userId: string) {
  return prisma.textSession.findMany({
    where: { userId },
    orderBy: { createdAt: "desc" },
    take: 50,
    select: {
      id: true, sourceType: true, readabilityTarget: true, createdAt: true,
      simplifiedText: true,
    },
  });
}

export async function getSession(userId: string, id: string) {
  await assertTextSessionOwner(id, userId);
  return prisma.textSession.findUnique({
    where: { id },
    include: { chunks: { orderBy: { chunkIndex: "asc" } } },
  });
}

export async function deleteSession(userId: string, id: string) {
  await assertTextSessionOwner(id, userId);
  await prisma.textSession.delete({ where: { id } });
  await audit(userId, "reading.session_delete", "text_session", id);
}
