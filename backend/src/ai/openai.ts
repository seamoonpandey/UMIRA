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
    const userMsg = messages.find((m) => m.role === "user")?.content ?? "";
    if (userMsg.toLowerCase().includes("simplif")) {
      return {
        summary: "This is a simplified placeholder summary.",
        chunks: [{ original: userMsg.slice(0, 200), simplified: "Plain summary of the text." }],
        key_terms: [],
      };
    }
    if (userMsg.toLowerCase().includes("reflect")) {
      return { reflection: "Nice work finishing this session. Maybe take a short stretch." };
    }
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
