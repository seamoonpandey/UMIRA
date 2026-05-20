import { env } from "../../config/env.js";

const HF_MODEL = "elvisbakunzi/dyslexia-friendly-text-simplifier";
const HF_API_URL = `https://api-inference.huggingface.co/models/${HF_MODEL}`;

export async function simplifyWithBart(text: string): Promise<string> {
  if (!env.HUGGINGFACE_API_KEY) {
    // Fallback: return a simpler version of the text
    return fallbackSimplify(text);
  }

  try {
    const response = await fetch(HF_API_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${env.HUGGINGFACE_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        inputs: text,
        parameters: {
          max_length: 256,
          num_beams: 3,
          length_penalty: 0.8,
          early_stopping: true,
          no_repeat_ngram_size: 2,
        },
      }),
    });

    if (!response.ok) {
      throw new Error(`HuggingFace API error: ${response.status}`);
    }

    const result = await response.json();
    // HF inference API returns [{ generated_text: "..." }]
    if (Array.isArray(result) && result[0]?.generated_text) {
      return result[0].generated_text;
    }
    if (typeof result === "string") return result;

    throw new Error("Unexpected HuggingFace response format");
  } catch (err) {
    console.warn("BART simplification failed, using fallback:", (err as Error).message);
    return fallbackSimplify(text);
  }
}

function fallbackSimplify(text: string): string {
  // Simple sentence splitting and shortening as graceful degradation
  const sentences = text.match(/[^.!?]+[.!?]+/g) || [text];
  return sentences
    .map((s) => {
      const trimmed = s.trim();
      if (trimmed.split(/\s+/).length > 20) {
        const words = trimmed.split(/\s+/);
        const mid = Math.ceil(words.length / 2);
        return words.slice(0, mid).join(" ") + ". " + words.slice(mid).join(" ");
      }
      return trimmed;
    })
    .join(" ");
}
