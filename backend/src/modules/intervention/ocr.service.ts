import Tesseract from "tesseract.js";

export async function performOcr(imageBuffer: Buffer): Promise<string> {
  const result = await Tesseract.recognize(imageBuffer, "eng", {
    logger: () => {}, // silence progress logs
  });

  return result.data.text.trim();
}
