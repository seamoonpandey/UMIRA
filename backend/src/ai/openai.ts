import OpenAI from "openai";
import { env } from "../config/env.js";
import type { AIProvider, ChatMessage } from "./provider.js";

export class OpenAIProvider implements AIProvider {
  private client: OpenAI;
  private model: string;
  private allowJsonMode: boolean;

  constructor(opts?: { baseURL?: string; apiKey?: string; model?: string; allowJsonMode?: boolean }) {
    this.client = new OpenAI({
      apiKey: opts?.apiKey ?? env.OPENAI_API_KEY,
      baseURL: opts?.baseURL ?? undefined,
    });
    this.model = opts?.model ?? env.OPENAI_MODEL;
    this.allowJsonMode = opts?.allowJsonMode ?? true;
  }

  name() { return "openai:" + this.model; }

  async chatJson(opts: { messages: ChatMessage[]; maxTokens?: number; temperature?: number }) {
    const res = await this.client.chat.completions.create({
      model: this.model,
      messages: opts.messages,
      temperature: opts.temperature ?? 0.2,
      max_tokens: opts.maxTokens ?? 1200,
      ...(this.allowJsonMode ? { response_format: { type: "json_object" as const } } : {}),
      ...(this.model.toLowerCase().includes("deepseek") ? { extra_body: { chat_template_kwargs: { thinking: false } } } : {}),
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
      // Extract original text from user message (format: "Text: <text>\nReading preference: ...")
      const origMatch = userMsg.match(/^Text:\s*(.+)$/m);
      const originalText = origMatch ? origMatch[1] : userMsg.slice(0, 200);
      // Use first 2 sentences from original as simplified to pass grounding validator
      const firstSentence = originalText.split(/[.!?]/).slice(0, 1).join(".").trim();
      const simplified = firstSentence.length > 10 ? firstSentence : originalText.slice(0, 100);
      return {
        summary: simplified.length > 80 ? simplified.slice(0, 80) + "." : simplified,
        chunks: [
          { original: originalText.slice(0, 200), simplified },
        ],
        key_terms: [],
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
