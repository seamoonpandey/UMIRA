import Groq from "groq-sdk";
import { env } from "../../config/env.js";

let groqClient: Groq | null = null;

function getGroq(): Groq {
  if (!groqClient) {
    if (!env.GROQ_API_KEY) {
      throw new Error("GROQ_API_KEY not configured");
    }
    groqClient = new Groq({ apiKey: env.GROQ_API_KEY });
  }
  return groqClient;
}

interface ProcessedWord {
  word: string;
  start: number;
  end: number;
  pauseMs: number;
  durationRatio: number;
  speechRateWpm: number;
  status?: string;
  skipped?: boolean;
  repetition?: boolean;
}

interface TranscriptionWord {
  word: string;
  start: number;
  end: number;
}

export async function analyzePracticeAudio(
  audioBuffer: Buffer,
  mimeType: string,
  expectedText: string = "The boy went to the store to buy some candy.",
) {
  const groq = getGroq();

  // Convert buffer to a File-like object for Groq
  const blob = new Blob([new Uint8Array(audioBuffer)], { type: mimeType });
  const file = new File([blob], `recording.${mimeType.split("/")[1] || "wav"}`, { type: mimeType });

  // Transcribe with Whisper via Groq
  const transcription = await groq.audio.transcriptions.create({
    file,
    model: "whisper-large-v3-turbo",
    response_format: "verbose_json",
    temperature: 0.0,
    language: "en",
  });

  // Extract word-level timings
  const words = extractWords(transcription);
  const processedWords = extractSignals(words);
  const finalData = alignAndAnalyze(expectedText, processedWords);

  // Calculate summary stats
  const skippedCount = finalData.filter((w) => w.skipped).length;
  const repetitions = finalData.filter((w) => w.repetition).length;
  const validRates = finalData
    .filter((w) => (w.speechRateWpm ?? 0) > 0)
    .map((w) => w.speechRateWpm ?? 0);
  const avgWpm = validRates.length > 0
    ? validRates.reduce((a, b) => a + b, 0) / validRates.length
    : 0;

  return {
    wordData: finalData,
    stats: {
      skippedWords: skippedCount,
      repetitions,
      wpm: Math.round(avgWpm * 10) / 10,
    },
  };
}

function extractWords(transcription: any): TranscriptionWord[] {
  const result: TranscriptionWord[] = [];

  if (transcription.words) {
    for (const w of transcription.words) {
      result.push({
        word: (w.word || "").trim().toLowerCase(),
        start: w.start ?? 0,
        end: w.end ?? 0,
      });
    }
  } else if (transcription.segments) {
    for (const segment of transcription.segments) {
      const segText: string = segment.text || "";
      const segWords = segText.trim().split(/\s+/);
      if (segWords.length === 0) continue;

      const durationPerWord = ((segment.end ?? 0) - (segment.start ?? 0)) / segWords.length;
      let currentTime = segment.start ?? 0;

      for (const w of segWords) {
        result.push({
          word: w.trim().toLowerCase(),
          start: currentTime,
          end: currentTime + durationPerWord,
        });
        currentTime += durationPerWord;
      }
    }
  }

  return result;
}

function extractSignals(words: TranscriptionWord[]): ProcessedWord[] {
  const processed: ProcessedWord[] = [];
  const avgWordDuration = 0.4;

  for (let i = 0; i < words.length; i++) {
    const w = words[i];
    const pauseMs = i > 0 ? Math.max(0, (w.start - words[i - 1].end) * 1000) : 0;
    const duration = w.end - w.start;
    const durationRatio = duration / avgWordDuration;

    let speechRateWpm = 0;
    if (i >= 4) {
      const windowStart = words[i - 4].start;
      const windowDuration = w.end - windowStart;
      if (windowDuration > 0) {
        speechRateWpm = (5 / windowDuration) * 60;
      }
    }

    processed.push({
      word: w.word,
      start: w.start,
      end: w.end,
      pauseMs: Math.round(pauseMs * 100) / 100,
      durationRatio: Math.round(durationRatio * 100) / 100,
      speechRateWpm: Math.round(speechRateWpm * 100) / 100,
    });
  }

  return processed;
}

function alignAndAnalyze(expectedText: string, processedWords: ProcessedWord[]): any[] {
  const expectedWords = expectedText.toLowerCase().split(/\s+/);
  const spokenWords = processedWords.map((w) => w.word);

  // LCS-based alignment
  const dataset: any[] = [];
  let ei = 0;
  let si = 0;

  while (ei < expectedWords.length || si < spokenWords.length) {
    if (ei < expectedWords.length && si < spokenWords.length && expectedWords[ei] === spokenWords[si]) {
      // Correct match
      const w = { ...processedWords[si] };
      w.status = "correct";
      w.skipped = false;
      w.repetition = false;
      dataset.push(w);
      ei++;
      si++;
    } else if (si < spokenWords.length && (ei >= expectedWords.length || spokenWords[si] !== expectedWords[ei])) {
      // Check if this is a repetition of the last spoken word
      const isRepetition = dataset.length > 0 && dataset[dataset.length - 1].word === spokenWords[si];
      const w = { ...processedWords[si] };
      w.status = isRepetition ? "repetition" : "insertion";
      w.skipped = false;
      w.repetition = isRepetition;
      dataset.push(w);
      si++;
    } else if (ei < expectedWords.length) {
      // Expected word was skipped
      dataset.push({
        word: expectedWords[ei],
        status: "skipped",
        skipped: true,
        pauseMs: 0,
        durationRatio: 0,
        repetition: false,
      });
      ei++;
    }
  }

  return dataset;
}
