# UMIRA - Neurodiversity-Centered Cognitive Support Platform

UMIRA is a calm, adaptive workspace that helps neurodivergent users start, read, focus, finish, and reflect without shame, clutter, or hidden manipulation. Positioned as general wellness and assistive productivity, not as a diagnostic or therapeutic device.

## Modules (MVP)

1. **Microtask Engine** - converts a goal into 3-12 atomic, low-friction steps
2. **Reading Support** - original/simplified toggle, line focus, spacing, read-aloud
3. **Focus Sessions** - 10/15/20/25-minute sprints with optional reflection
4. **Cognitive Preference Profile** - explicit user-controlled settings; no inferred diagnosis
5. **First-Party Analytics** - personal trends; export and hard-delete from settings

## Stack

- Backend: Node 20, Fastify, TypeScript, Prisma, PostgreSQL, Redis, Zod
- AI: provider-abstracted (OpenAI + Anthropic) hybrid rules + LLM with validators
- Mobile: Flutter 3.x, Riverpod, GoRouter, flutter_tts, dio
- Infra: Docker Compose, GitHub Actions CI

## Quick Start

```bash
cp .env.example .env
# fill in OPENAI_API_KEY or ANTHROPIC_API_KEY and JWT_SECRET
docker compose up -d postgres redis
cd backend
npm install
npx prisma migrate dev --name init
npm run seed
npm run dev
# in another terminal:
cd mobile
flutter pub get
flutter run
```

## Responsible Use

UMIRA is **not** a diagnostic tool. It does **not** provide medical advice or treatment. If you are in crisis, contact local emergency services.

## License

MIT
