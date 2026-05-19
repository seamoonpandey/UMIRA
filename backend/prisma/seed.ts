import { PrismaClient } from "@prisma/client";
import argon2 from "argon2";

const prisma = new PrismaClient();

async function main() {
  const passwordHash = await argon2.hash("DemoPass!234");
  const demo = await prisma.user.upsert({
    where: { email: "demo@umira.app" },
    update: {},
    create: {
      email: "demo@umira.app",
      passwordHash,
      preferences: {
        create: {
          textDensity: "comfortable",
          fontScale: 1.1,
          useDyslexiaFont: true,
          sessionLengthDefault: 15,
        },
      },
    },
  });
  // eslint-disable-next-line no-console
  console.log("Seeded demo user:", demo.email);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => prisma.$disconnect());
