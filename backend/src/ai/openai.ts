import OpenAI from "openai";
import { env } from "../config/env.js";
import type { AIProvider, ChatMessage } from "./provider.js";

export class OpenAIProvider implements AIProvider {
  private client = new OpenAI({ apiKey: env.OPENAI_API_KEY });
  name() { return "openai:" + env.OPENAI_MODEL; }
  async chatJson(opts: { messages: ChatMessage[]; maxTokens?: number; temperature?: number }) {
    const res = await this.client.chat.completions.create({
      model: env.OPENAI_MODEL,
      messages: opts.messages,
      temperature: opts.temperature ?? 0.2,
      max_tokens: opts.maxTokens ?? 1200,
      response_format: { type: "json_object" },
    });
    const content = res.choices[0]?.message?.content ?? "{}";
    return JSON.parse(content);
  }
}

export class MockProvider implements AIProvider {
  name() { return "mock:deterministic"; }
  async chatJson({ messages }: { messages: ChatMessage[] }) {
    const systemMsg = messages.find((m) => m.role === "system")?.content ?? "";
    const userMsg = messages.find((m) => m.role === "user")?.content ?? "";

    // Route by system prompt to avoid keyword collision in user messages
    if (systemMsg.includes("rewrite text to reduce cognitive load")) {
      return {
        summary: "This text discusses how to reduce cognitive load through clear writing.",
        chunks: [
          { original: userMsg.slice(0, 200), simplified: "Clear writing helps reduce mental effort when reading." },
        ],
        key_terms: [{ term: "Cognitive load", definition: "The amount of mental effort needed to process information" }],
      };
    }
    if (systemMsg.includes("short, warm, non-judgmental")) {
      return { reflection: "Nice work finishing this session. Maybe take a short stretch." };
    }
    // Default: microtask generation
    return {
      steps: [
        { label: "Open the document you need", estimated_minutes: 2 },
        { label: "Read the first paragraph", estimated_minutes: 3 },
        { label: "Write three bullet points", estimated_minutes: 5 },
      ],
      refusal: null,
    };
  }
}
