import { defineConfig } from "vitest/config";
import path from "node:path";
import fs from "node:fs";

export default defineConfig({
  plugins: [
    {
      name: "resolve-js-to-ts",
      enforce: "pre",
      resolveId(source: string, importer: string | undefined) {
        // If importing a .js file from within the project, try .ts instead
        if (
          source.endsWith(".js") &&
          importer &&
          !source.startsWith(".") &&
          !source.startsWith("/")
        ) {
          return null; // let Vite handle node_modules normally
        }
        if (source.endsWith(".js") && importer) {
          // Try .ts first, then .tsx
          const tsPath = source.replace(/\.js$/, ".ts");
          const tsxPath = source.replace(/\.js$/, ".tsx");
          const dir = path.dirname(importer);
          const tsResolved = path.resolve(dir, tsPath);
          const tsxResolved = path.resolve(dir, tsxPath);
          if (fs.existsSync(tsResolved)) return tsResolved;
          if (fs.existsSync(tsxResolved)) return tsxResolved;
        }
        return null;
      },
    },
  ],
  test: {
    globals: true,
    environment: "node",
    setupFiles: ["./src/__tests__/setup.ts"],
    include: ["src/__tests__/**/*.test.ts"],
    testTimeout: 15_000,
    hookTimeout: 15_000,
    forceExit: true,
    server: {
      deps: {
        inline: ["@fastify", "fastify"],
      },
    },
  },
});
