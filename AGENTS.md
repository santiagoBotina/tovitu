# Tovitu

AI-powered pet adoption platform (MVP stage). Reduces failed adoptions through better preparation.

**Current state:** Rails 8.1.3 application initialized. See README.md for setup instructions.
See `.opencode/agents/*.md` for role-specific patterns, ownership, and constraints — those are the authoritative source for implementation guidance.

## Planned Stack

Rails 8, PostgreSQL, Sidekiq/Redis, Active Storage + Cloudflare R2, Anthropic API, WhatsApp Business API, Hotwire/Turbo/Stimulus.

## Domain Architecture

Business logic is organized by domain under `lib/`:
- `adoptions/` — adoption applications and workflows
- `pets/` — pet management
- `shelters/` — shelter management
- `messaging/` — WhatsApp and other communications
- `ai/` — AI life previews and analysis

## Key Conventions

- **Spec-driven:** Before implementing, first create a plan at `/specs/<timestamp>_<feature-name>_plan.md`, then create `/specs/<feature-name>/specification.md` + `acceptance-criteria.md`.
- **Plan first:** Every feature starts with a plan document in `/specs/`. The plan defines scope, approach, and risks before any code is written.
- **AI vendor-agnostic:** Adapt around Anthropic; never couple business logic to a provider API.
- **Messaging vendor-agnostic:** Isolate WhatsApp behind `Messaging::*` service objects.
- **Prompts in `config/prompts/`:** Never hardcode prompts inline.
- **i18n:** All user-facing strings go in `config/locales/*.yml`. Use `t()` in views/controllers/mailers, `I18n.t()` in service objects/presenters. No hardcoded user-facing strings.
- **Request specs over controller specs.**
- **Pundit for authorization** — never check auth in views.
- **Form/Query/Service/Presenter/Value objects** for separation of concerns (detailed per agent in `.opencode/agents/*.md`).
- **Deployment decoupled:** No deployment tooling in the repo. Add deployment strategy when ready for production.

## Agent Directory Ownership

**Primary agents:** `build`, `plan`, and `product`.

`product` owns `/specs` (spec creation per the spec-driven convention). `build` and `plan` are the built-in primary agents; `plan` owns pre-implementation planning.

The domain agents below are **subagents** (see `.opencode/agents/*.md`). They are independent, write/modify code in their area of ownership, and are invoked by primary agents when a spec requires their domain.

| Subagent | Owns |
|-------|------|
| AI | `lib/ai`, `config/prompts` |
| Data | `db/`, `app/models/` |
| Domain | `lib/adoptions`, `lib/pets`, `lib/shelters` |
| Frontend | `app/views`, `app/components`, `app/javascript` |
| Spec | technical design + implementation from `/specs/*` |
| QA | `spec/` |

## Design Context

See [PRODUCT.md](/PRODUCT.md) for strategic context (register, users, brand personality, design principles) and [DESIGN.md](/DESIGN.md) for the visual system (colors, typography, elevation, components, do's and don'ts). Creative North Star: **The Playground Standard** — a refined neubrutalism direction: bold, playful, friendly, with generous targets, flat surfaces, and saturated color blocks. WCAG AA target. All visual decisions must honor DESIGN.md before introducing new tokens.
