import { env } from "../config/env.js";
import type { AIProvider, ChatMessage } from "./provider.js";

interface AnthropicResponse {
  content: Array<{ type: string; text?: string }>;
}

export class AnthropicProvider implements AIProvider {
  name() { return "anthropic:" + env.ANTHROPIC_MODEL; }
  async chatJson(opts: { messages: ChatMessage[]; maxTokens?: number; temperature?: number }) {
    const system = opts.messages.filter((m) => m.role === "system").map((m) => m.content).join("\n\n");
    const user = opts.messages.filter((m) => m.role === "user").map((m) => m.content).join("\n\n");
    const res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": env.ANTHROPIC_API_KEY!,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: env.ANTHROPIC_MODEL,
        max_tokens: opts.maxTokens ?? 1200,
        temperature: opts.temperature ?? 0.2,
        system: system + "\nRespond with valid JSON only.",
        messages: [{ role: "user", content: user }],
      }),
    });
    if (!res.ok) throw new Error(`Anthropic error ${res.status}: ${await res.text()}`);
    const data = (await res.json()) as AnthropicResponse;
    const text = data.content.find((c) => c.type === "text")?.text ?? "{}";
    const jsonStart = text.indexOf("{");
    const jsonEnd = text.lastIndexOf("}");
    return JSON.parse(text.slice(jsonStart, jsonEnd + 1));
  }
}
