import { initSentry } from "./config/sentry.js";

initSentry();

import { buildApp } from "./app.js";
import { env } from "./config/env.js";
import { logger } from "./config/logger.js";
import { prisma } from "./db/prisma.js";

async function main() {
  const app = await buildApp();

  const signals = ["SIGTERM", "SIGINT"] as const;
  for (const signal of signals) {
    process.on(signal, async () => {
      logger.info(`received ${signal}, shutting down`);
      await app.close();
      await prisma.$disconnect();
      process.exit(0);
    });
  }

  await app.listen({ port: env.PORT, host: "0.0.0.0" });
  logger.info(`UMIRA API listening on :${env.PORT}`);
}

main().catch((err) => {
  logger.error(err);
  process.exit(1);
});
