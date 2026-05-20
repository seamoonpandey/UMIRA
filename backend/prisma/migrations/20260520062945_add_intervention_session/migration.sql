-- CreateTable
CREATE TABLE "InterventionSession" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "score" INTEGER,
    "total" INTEGER,
    "wpm" INTEGER,
    "accuracy" INTEGER,
    "grapheme" TEXT,
    "phoneme" TEXT,
    "statsJson" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "InterventionSession_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "InterventionSession_userId_createdAt_idx" ON "InterventionSession"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "InterventionSession_type_createdAt_idx" ON "InterventionSession"("type", "createdAt");

-- AddForeignKey
ALTER TABLE "InterventionSession" ADD CONSTRAINT "InterventionSession_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
