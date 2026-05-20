import { env } from "../config/env.js";

export interface ChatMessage {
  role: "system" | "user";
  content: string;
}

export interface AIProvider {
  chatJson(opts: { messages: ChatMessage[]; maxTokens?: number; temperature?: number }): Promise<unknown>;
  name(): string;
}

export async function getProvider(): Promise<AIProvider> {
  if (env.AI_PROVIDER === "openai" && env.OPENAI_API_KEY) {
    const { OpenAIProvider } = await import("./openai.js");
    return new OpenAIProvider();
  }
  if (env.AI_PROVIDER === "anthropic" && env.ANTHROPIC_API_KEY) {
    const { AnthropicProvider } = await import("./anthropic.js");
    return new AnthropicProvider();
  }
  if (env.AI_PROVIDER === "nvidia" && env.NVIDIA_NIM_API_KEY) {
    const { OpenAIProvider } = await import("./openai.js");
    return new OpenAIProvider({
      baseURL: env.NVIDIA_NIM_BASE_URL,
      apiKey: env.NVIDIA_NIM_API_KEY,
      model: env.NVIDIA_NIM_MODEL,
    });
  }
  const { MockProvider } = await import("./openai.js");
  return new MockProvider();
}
