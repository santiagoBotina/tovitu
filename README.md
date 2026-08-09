# Tovitu

AI-powered pet adoption platform. Reduces failed adoptions through AI life previews, adoption guidance, and post-adoption support.

## Prerequisites

- **Ruby 4.0+** — managed via `rbenv` (see `.ruby-version`)
- **Docker Desktop** — for PostgreSQL 16 and LocalStack (AWS emulation) containers
- **Foreman** — installed automatically via `tailwindcss-rails`

## Quick Start

```bash
cp .env.example .env          # Edit .env with your API keys
bin/setup                     # Starts Docker services, installs gems, creates DB, starts server
```

Or step-by-step:

```bash
make docker-up                # Start PostgreSQL + LocalStack (removes retired containers)
bundle install                # Install Ruby gems
rails db:prepare              # Create and migrate database
bin/dev                       # Start server + Tailwind watcher + SQS worker
```

LocalStack emulates every AWS dependency locally (S3 storage, SQS jobs, SES email,
Cognito auth, Secrets Manager, EventBridge Scheduler). Verify the footprint with
`bin/rails aws:smoke`. Inspect queues/email via the `awslocal` CLI inside the container
(`docker compose exec localstack awslocal ...`).

## Architecture

### Domain Structure

```
lib/                          # Business logic organized by domain
  ai/                         # AI life previews & analysis (provider-agnostic)
    generate_life_preview.rb  #   Ai::GenerateLifePreview
    compatibility_analyzer.rb #   Ai::CompatibilityAnalyzer
    prompt_builder.rb         #   Ai::PromptBuilder
  messaging/                  # WhatsApp communication (provider-agnostic)
    send_message.rb           #   Messaging::SendMessage
    receive_webhook.rb        #   Messaging::ReceiveWebhook
    start_conversation.rb     #   Messaging::StartConversation
    base_provider.rb          #   Messaging::BaseProvider (adapter interface)
  adoptions/                  # Adoption applications & workflows
  pets/                       # Pet management
  shelters/                   # Shelter management
  application_service.rb      # Base callable service pattern
  application_query.rb        # Base query object pattern
  result.rb                   # Immutable Result value object (success/failure)

app/
  forms/                      # Form objects (ActiveModel::Model)
    application_form.rb       #   ApplicationForm
  presenters/                 # Presenter/decorator pattern (SimpleDelegator)
    application_presenter.rb  #   ApplicationPresenter
  policies/                   # Pundit authorization
    application_policy.rb     #   ApplicationPolicy

config/
  prompts/                    # AI prompt templates (never hardcoded inline)
    life_preview.yml          #   Life preview generation prompt
    compatibility.yml         #   Compatibility analysis prompt
  storage.yml                 # Active Storage: LocalStack S3 (dev), Amazon S3 (prod)
  queuing/ (lib)              # SQS seam: Queuing::Client / Worker / QueueRegistry
```

### Key Decisions

| Decision | Rationale |
|----------|-----------|
| Rails monolith | Simplicity, fast iteration, avoid distributed complexity for MVP |
| Docker for infra only | Faster dev iteration than containerized Rails; app runs natively |
| `lib/` for domain code | Rails 8's `config.autoload_lib` provides proper Zeitwerk namespacing (`Ai::GenerateLifePreview`) |
| Service/Query/Form/Presenter | Keep models thin, controllers thin, views simple |
| Result value object | Errors-as-values across all service boundaries |
| SQS (LocalStack locally) | Durable Active Job backend behind `lib/queuing/`; DLQ-backed, no Redis |
| S3 (LocalStack locally) | Active Storage object storage via Amazon S3 |
| Rails auth (no Devise) | Built-in `has_secure_password`, `authenticate_by` — sufficient for MVP |
| Pundit | Explicit policy objects; no auth logic in views or controllers |
| Request specs > controller specs | Full middleware coverage (auth, routing, params, rendering) |
| YAML prompt files | AI prompts version-controlled, auditable, swapable by environment |

### Tooling

- **Hotwire** (Turbo + Stimulus) for dynamic UI without SPA complexity
- **TailwindCSS** via `tailwindcss-rails` gem (standalone CLI, no Node needed)
- **Importmap** for JavaScript dependencies (no bundler)
- **RuboCop** with `rubocop-rails-omakase` style guide

## Development Workflow

```bash
bin/dev                       # Foreman: web + css:watch + worker
rails generate rspec:install  # Already ran; generators produce spec files
```

### Code Quality

- `bin/rubocop` — linting
- `bin/brakeman` — security analysis
- `bin/bundler-audit` — dependency vulnerabilities

## Testing

```bash
rails db:prepare RAILS_ENV=test   # First time only
rspec                              # Run all specs
rspec spec/lib                     # Run domain tests
rspec spec/requests                # Run request specs
```

## Deployment

Production uses:

- **Database:** PostgreSQL (via `DATABASE_URL`)
- **Jobs:** SQS (Active Job adapter + `bin/rails queuing:work` worker)
- **Storage:** Amazon S3 (Active Storage, via `storage.yml` `amazon` service)
- **AI:** Anthropic API (via `ANTHROPIC_API_KEY`)
- **Messaging:** WhatsApp Business API

Deployment is not configured in this repo — decoupled by design. Add a deployment strategy (Kamal, Fly, Render, etc.) when the application is ready for production.

## Domain Roadmap

1. **Authentication** — Rails auth + User model
2. **Shelters** — Registration, management portal
3. **Pets** — CRUD, image uploads, search
4. **Adoptions** — Application workflow, questionnaires
5. **AI** — Life preview generation, compatibility analysis
6. **Messaging** — WhatsApp notifications, conversation flows
7. **Post-adoption** — Follow-ups, support, success tracking
