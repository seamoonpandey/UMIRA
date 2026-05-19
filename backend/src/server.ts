import { buildApp } from "./app.js";
import { env } from "./config/env.js";
import { logger } from "./config/logger.js";

async function main() {
  const app = await buildApp();
  await app.listen({ port: env.PORT, host: "0.0.0.0" });
  logger.info(`UMIRA API listening on :${env.PORT}`);
}

main().catch((err) => {
  logger.error(err);
  process.exit(1);
});
