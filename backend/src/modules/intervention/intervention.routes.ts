import type { FastifyInstance } from "fastify";
import { authenticate } from "../../auth/middleware.js";
import { analyzePracticeAudio } from "./intervention.service.js";
import { performOcr } from "./ocr.service.js";
import { SaveInterventionSession } from "./intervention.schemas.js";
import { z } from "zod";

export default async function interventionRoutes(app: FastifyInstance) {
  app.addHook("preHandler", authenticate);

  /* ── Groq Whisper Speech Analysis ──────────────────────────────── */

  app.post("/intervention/analyze-practice", async (req, reply) => {
    const file = await req.file();
    if (!file) {
      return reply.code(400).send({ error: "No audio file provided" });
    }

    const expectedTextRaw = (file.fields.expectedText as any)?.value as string | undefined;
    const expectedText = expectedTextRaw || "The boy went to the store to buy some candy.";

    const buffer = await file.toBuffer();

    try {
      const result = await analyzePracticeAudio(buffer, file.mimetype, expectedText);
      return result;
    } catch (err: any) {
      req.log.error({ err }, "Practice analysis failed");
      return reply.code(500).send({ error: err.message || "Analysis failed" });
    }
  });

  /* ── OCR Text Extraction ───────────────────────────────────────── */

  app.post("/intervention/ocr", async (req, reply) => {
    const file = await req.file();
    if (!file) {
      return reply.code(400).send({ error: "No image file provided" });
    }

    const buffer = await file.toBuffer();

    try {
      const text = await performOcr(buffer);
      return { text };
    } catch (err: any) {
      req.log.error({ err }, "OCR failed");
      return reply.code(500).send({ error: err.message || "OCR failed" });
    }
  });

  /* ── Text Simplification via BART/HuggingFace ──────────────────── */

  const SimplifyBody = z.object({
    text: z.string().min(1).max(5000),
  });

  app.post("/intervention/simplify", async (req, reply) => {
    const { text } = SimplifyBody.parse(req.body);

    try {
      const { simplifyWithBart } = await import("./simplify.service.js");
      const result = await simplifyWithBart(text);
      return { simplified: result };
    } catch (err: any) {
      req.log.error({ err }, "BART simplification failed");
      return reply.code(500).send({ error: err.message || "Simplification failed" });
    }
  });

  /* ── Save intervention session ─────────────────────────────────── */

  app.post("/intervention/sessions", async (req) => {
    const body = SaveInterventionSession.parse(req.body);

    // Log as analytics event for now
    const { prisma } = await import("../../db/prisma.js");
    const session = await prisma.analyticsEvent.create({
      data: {
        userId: req.user.id,
        eventName: `intervention.${body.type}`,
        eventProps: {
          score: body.score,
          total: body.total,
          wpm: body.wpm,
          accuracy: body.accuracy,
          grapheme: body.grapheme,
          phoneme: body.phoneme,
          stats: body.stats,
          timestamp: new Date().toISOString(),
        },
      },
    });

    return { ok: true, id: session.id };
  });

  /* ── List intervention history ──────────────────────────────────── */

  app.get("/intervention/sessions", async (req) => {
    const { prisma } = await import("../../db/prisma.js");
    const sessions = await prisma.analyticsEvent.findMany({
      where: {
        userId: req.user.id,
        eventName: { startsWith: "intervention." },
      },
      orderBy: { createdAt: "desc" },
      take: 100,
    });

    return {
      sessions: sessions.map((s) => ({
        id: s.id,
        type: s.eventName.replace("intervention.", ""),
        date: s.createdAt.toISOString(),
        ...(s.eventProps as any),
      })),
    };
  });
}
