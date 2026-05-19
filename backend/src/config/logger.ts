import pino from "pino";
import { env } from "./env.js";

const isDev = env.NODE_ENV === "development";
const isTest = env.NODE_ENV === "test";

function reqSerializer(req: any) {
  return {
    method: req.method,
    url: req.url,
    hostname: req.hostname,
    remoteAddress: req.ip,
  };
}

function resSerializer(res: any) {
  return { statusCode: res.statusCode };
}

function errSerializer(err: any) {
  return {
    type: err.name,
    message: err.message,
    stack: isDev ? err.stack : undefined,
    code: err.code,
  };
}

export const logger = pino({
  level: env.LOG_LEVEL,
  serializers: {
    req: reqSerializer,
    res: resSerializer,
    err: errSerializer,
  },
  redact: {
    paths: [
      "req.headers.authorization",
      "req.headers.cookie",
      "*.password",
      "*.passwordHash",
      "*.sourceText",
      "*.originalText",
      "*.simplifiedText",
      "*.aiJob.prompt",
    ],
    censor: "[REDACTED]",
  },
  formatters: isTest
    ? undefined
    : {
        level(label) {
          return { level: label };
        },
      },
  timestamp: pino.stdTimeFunctions.isoTime,
  transport:
    isDev
      ? { target: "pino-pretty", options: { colorize: true, translateTime: "HH:MM:ss" } }
      : undefined,
});
