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
- Infra: Docker Compose, GitHub Actions CI, nginx, Let's Encrypt, Prometheus

## Quick Start (Development)

```bash
# 1. Clone and set up environment
cp .env.example .env
# edit .env — fill in OPENAI_API_KEY or ANTHROPIC_API_KEY and JWT_SECRET

# 2. Start infrastructure (PostgreSQL + Redis)
docker compose up -d postgres redis

# 3. Start backend
cd backend
npm install
npx prisma migrate dev --name init
npm run seed
npm run dev

# 4. Start Flutter mobile app (in another terminal)
cd mobile
flutter pub get
flutter run
```

## Production Deployment

### Prerequisites
- Docker & Docker Compose on the target host
- Domain name (e.g., umira.app) with DNS pointing to the server
- Ports 80 and 443 open

### Step 1 — Set up SSL certificates
```bash
# Deploy the HTTP-only nginx config, then:
./infra/ssl/setup-ssl.sh --live
```

### Step 2 — Deploy
```bash
# Build and deploy all services
make deploy

# Or manually:
docker compose build
docker compose up -d
```

### Step 3 — Verify
```bash
curl https://umira.app/health
curl https://umira.app/docs          # Swagger UI
```

### Architecture
```
Internet
  │
  ▼  :443 (HTTPS)
nginx  ──► /v1/*  ──► backend:4000 (Fastify API)
  │        ├── postgres:5432
  │        └── redis:6379
  │
  └── /    ──►  Flutter web build (static files)
```

Metrics are available at `/metrics` (internal network only) when `PROMETHEUS_ENABLED=true`.

## Responsible Use

UMIRA is **not** a diagnostic tool. It does **not** provide medical advice or treatment. If you are in crisis, contact local emergency services.

## License

MIT
