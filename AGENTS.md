# AGENTS.md

# Tovitu Engineering Constitution

This document defines the engineering standards, architectural principles, and implementation guidelines that all AI agents and developers must follow when working on Tovitu.

The objective is to maintain a codebase that is:

* Simple
* Maintainable
* Testable
* Extensible
* Production-ready
* Consistent

The project is in its MVP stage and prioritizes speed of execution without sacrificing code quality.

---

# Product Context

Tovitu is an AI-powered pet adoption platform that helps prospective adopters understand what life with a specific pet would actually look like before adoption.

Core capabilities:

* Shelter management
* Pet management
* Adoption workflows
* AI-generated life previews
* WhatsApp automation
* Post-adoption support

The primary business goal is:

Reduce failed pet adoptions through better adopter preparation and guidance.

---

# Engineering Philosophy

## Optimize For Learning

The primary objective is validating product assumptions.

Prefer:

* Simplicity
* Fast iteration
* Clear architecture

Over:

* Premature optimization
* Complex abstractions
* Microservices

---

## Monolith First

Tovitu is intentionally built as a Rails monolith.

Do not introduce:

* Microservices
* Distributed systems
* Event buses
* Service meshes

Unless explicitly required by scale.

---

## Convention Over Configuration

Prefer Rails conventions whenever possible.

Avoid custom frameworks.

Avoid reinventing Rails patterns.

---

## YAGNI

You Aren't Gonna Need It.

Do not build future features.

Do not introduce abstractions for hypothetical requirements.

Implement only what is currently required.

---

# Technology Stack

## Backend

* Ruby 3.x (latest stable)
* Rails 8 (latest stable)

---

## Database

* PostgreSQL

---

## Background Processing

* Sidekiq
* Redis

---

## File Storage

* Active Storage
* Cloudflare R2

---

## AI Layer

* Anthropic API

Primary model provider.

All AI integrations must be provider-agnostic.

Create adapters to facilitate future model replacements.

---

## Messaging

* WhatsApp Business API

All messaging integrations must be isolated behind application services.

Never couple business logic to vendor APIs.

---

## Frontend

Rails-first approach.

Preferred stack:

* Rails Views
* Hotwire
* Turbo
* Stimulus

Avoid introducing React unless there is a clear product requirement.

---

## Deployment

* Docker
* Render, Fly.io, or equivalent

---

# Development Methodology

## Spec-Driven Development

All features begin with a specification.

Before writing code, create:

```text
/specs
  feature-name/
    specification.md
    acceptance-criteria.md
```

Every specification must define:

* Problem
* Business value
* User story
* Acceptance criteria
* Edge cases
* Success criteria

Code should be an implementation of the specification.

---

## Development Workflow

For every feature:

### Step 1

Read specification.

### Step 2

Identify domain concepts.

### Step 3

Design tests.

### Step 4

Implement feature.

### Step 5

Refactor.

### Step 6

Verify acceptance criteria.

---

# Testing Philosophy

Tests are mandatory.

No production feature is complete without tests.

---

## Testing Pyramid

### Unit Tests

Highest priority.

Test:

* Domain objects
* Services
* Policies
* Value objects

---

### Request Specs

Preferred over controller specs.

Test:

* API behavior
* Authentication
* Authorization

---

### System Specs

Cover:

* Critical user journeys
* Adoption workflows
* Shelter workflows

---

## Avoid

Excessive mocking.

Prefer real behavior whenever practical.

---

# Domain-Driven Structure

Organize code around business domains.

Prefer:

```text
app/
  domains/
    adoptions/
    pets/
    shelters/
    messaging/
    ai/
```

Over:

```text
app/
  services/
  models/
  controllers/
```

Business domains should be easy to identify.

---

# Service Object Pattern

Complex business logic must not live inside controllers.

Use service objects.

Example:

```ruby
Adoptions::CreateApplication
Pets::GenerateLifePreview
Messaging::SendWhatsAppMessage
```

Services should:

* Have one responsibility
* Be deterministic
* Be testable

---

# Query Object Pattern

Complex queries belong in query objects.

Example:

```ruby
Pets::SearchQuery
Adoptions::EligibleMatchesQuery
```

Avoid large ActiveRecord scopes.

---

# Policy Pattern

Authorization must be explicit.

Use:

```ruby
Pundit
```

Never perform authorization checks directly in views.

---

# Presenter Pattern

Presentation logic belongs in presenters.

Avoid formatting logic inside views.

Example:

```ruby
PetPresenter
AdoptionPresenter
```

---

# Form Object Pattern

Use form objects for complex forms.

Example:

```ruby
AdoptionApplicationForm
ShelterRegistrationForm
```

---

# Value Objects

Use value objects for domain concepts.

Examples:

```ruby
Money
PhoneNumber
CompatibilityScore
PetAge
```

Prefer immutable objects.

---

# Rails Model Rules

Models should represent business entities.

Models should not become God Objects.

Avoid:

* External API calls
* Complex orchestration
* Long callback chains

Inside models.

---

# Background Jobs

Background jobs should orchestrate.

Business logic belongs elsewhere.

Good:

```ruby
GenerateLifePreviewJob
```

Bad:

```ruby
100+ lines of business logic inside jobs
```

---

# AI Integration Guidelines

All AI interactions must be isolated.

Use:

```ruby
Ai::GenerateLifePreview
Ai::CompatibilityAnalysis
```

Never call Anthropic directly from:

* Controllers
* Models
* Views

---

## Prompt Management

Store prompts in dedicated files.

Example:

```text
config/prompts/
```

Never hardcode prompts throughout the codebase.

---

# WhatsApp Integration Guidelines

All WhatsApp functionality must be vendor-agnostic.

Use:

```ruby
Messaging::SendMessage
Messaging::ReceiveWebhook
```

Wrap provider APIs.

Never couple business logic to Meta-specific APIs.

---

# API Design Guidelines

Follow REST conventions.

Use resource-oriented endpoints.

Example:

```text
GET    /pets
GET    /pets/:id

POST   /adoptions

PATCH  /adoptions/:id
```

Avoid RPC-style endpoints.

---

# Clean Code Standards

Functions should:

* Do one thing
* Have clear names
* Be short

Prefer:

```ruby
generate_preview
```

Over:

```ruby
process_pet_adoption_preview_generation_logic
```

---

## Naming

Names must reveal intent.

Avoid abbreviations.

Avoid ambiguous names.

Good:

```ruby
adoption_application
```

Bad:

```ruby
app
```

---

# Database Standards

Use database constraints.

Never rely exclusively on model validations.

Prefer:

* Foreign keys
* Unique indexes
* Check constraints

---

# Observability

Log meaningful events.

Examples:

* Adoption created
* Preview generated
* WhatsApp message sent

Avoid noisy logs.

---

# Security Standards

Always validate:

* Authorization
* Authentication
* Input data

Never trust user input.

Always use Rails security defaults.

---

# Performance Philosophy

Do not optimize prematurely.

Prioritize:

* Correctness
* Readability
* Maintainability

Measure before optimizing.

---

# Documentation Standards

Every domain must contain:

```text
README.md
```

Describing:

* Purpose
* Key workflows
* Business rules

---

# Accessibility

All user-facing interfaces must:

* Meet WCAG standards
* Support keyboard navigation
* Use semantic HTML
* Maintain proper contrast ratios

Accessibility is a requirement.

---

# Definition Of Done

A feature is complete only when:

* Specification exists
* Acceptance criteria pass
* Tests pass
* Authorization exists
* Documentation exists
* Code review passes
* No critical TODOs remain

If any of the above is missing, the feature is not complete.
