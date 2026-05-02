# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**minnit** is a mini Reddit-like discussion platform built with Rails 8.1 and Ruby 4.0.1.

This app is a learning exercise and not meant for production deployment.

Documentation artifacts should go in ./docs

Our users are called "members", not users. I may use the terms interchangably but you should use "members" both in replies and in the code.

## Code Conventions

- Favor descriptive identifier names that convey intent
- Favor foreign key names that include the name of the foreign table. Example: "user_created_by_id" not "created_by_id"
- Include unit names in identifiers. Example: "duration_seconds" not "duration"
- Runtime performance matters
- Minimize the dependency graph between models when possible
  - A model should not depend on another aside from association declarations

## Rails Model Coupling Rules

Goal: Models = data + invariants. No orchestration.

- Models (app/models)
  - OK: associations, validations, scopes, simple methods, normalization
  - NOT OK: cross-model writes, emails, jobs, APIs, workflows
- Services (app/services)
  - Multi-model workflows
  - Transactions + orchestration
- Queries (app/queries)
  - Complex reads / joins / reporting
- Forms (app/forms)
  - Multi-model form writes
- Jobs (app/jobs)
  - Async side effects (email/API)
  - Pass IDs, not objects
- Callbacks
  - OK: local only
  - Avoid: anything external or cross-model
- Rules
  - No model → model orchestration
  - Workflows → services
  - Side effects → jobs/services
  - Prefer explicit dependencies

## Repository Layout

The Rails application lives in `code/` — run all Rails/Bundler commands from there:

```text
minnit/
├── code/          ← Rails root (cd here to run bin/* commands)
├── docs/
└── README.md
```

## Commands

All commands run from `code/`:

```bash
# First-time setup
bin/setup

# Start dev server
bin/dev

# Run all tests
bin/rails db:test:prepare test

# Run system tests (Capybara + Selenium)
bin/rails db:test:prepare test:system

# Run a single test file or specific line
bin/rails test test/models/post_test.rb
bin/rails test test/models/post_test.rb:42

# Lint (rubocop-rails-omakase style)
bin/rubocop

# Security scans (all three run in CI)
bin/brakeman --no-pager
bin/bundler-audit
bin/importmap audit
```

## Architecture

**Stack**: Rails 8.1 · Ruby 4.0.1 · SQLite3 · Hotwire (Turbo + Stimulus) · Propshaft · Importmap

**"Solid" adapters** replace Redis entirely:

- `solid_cache` → Rails.cache
- `solid_queue` → Active Job
- `solid_cable` → Action Cable

In production, four separate SQLite databases back these (`storage/production*.sqlite3`). In development, a single `storage/development.sqlite3` is used.

**Deployment** is Docker-based via Kamal (`config/deploy.yml`). `RAILS_MASTER_KEY` is the only required secret. Solid Queue runs inside Puma (`SOLID_QUEUE_IN_PUMA: true`).

**JavaScript**: ES modules via importmap — no Node/npm build step required.

## CI Pipeline

GitHub Actions runs five jobs: `scan_ruby` (brakeman), `scan_js` (importmap audit), `lint` (rubocop), `test` (unit/integration), `system-test` (Capybara). All must pass on PRs to `main`.
