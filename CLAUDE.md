# Rails App Starter Kit — CLAUDE.md

## Overview

Rails 8.1 starter kit with Devise authentication, Tailwind CSS v4, RSpec, and PostgreSQL pre-configured. Includes a UI at `/setup` to rename the app.

## Tech Stack

- **Ruby on Rails** 8.1.4 (Ruby 4.0.9)
- **Hotwire**: Turbo + Stimulus (via jsbundling-rails + stimulus-rails)
- **Tailwind CSS** v4 (via cssbundling-rails + @tailwindcss/cli)
- **PostgreSQL** (database)
- **Devise** (authentication)
- **RSpec** (testing) + Capybara + Selenium WebDriver
- **esbuild** (JS bundling)
- **Propshaft** (asset pipeline)

## Commands

```bash
# Start dev server
bin/dev

# Run all specs
bundle exec rspec

# Run specific spec file
bundle exec rspec spec/models/user_spec.rb

# Run rubocop
bundle exec rubocop

# Database
bin/rails db:create
bin/rails db:migrate
bin/rails db:test:prepare
bin/rails db:seed

# Asset builds (handled by bin/dev via Procfile.dev)
yarn build          # JS via esbuild
yarn build:css      # Tailwind CSS
```

## Project Structure

- `app/models/` — ActiveRecord models (User with Devise)
- `app/controllers/` — Rails controllers (use `before_action :authenticate_user!` for auth)
- `app/views/` — ERB templates (Tailwind-styled)
- `app/services/` — Service objects (AppRenameService)
- `app/javascript/controllers/` — Stimulus controllers (auto-registered via index.js)
- `app/assets/stylesheets/application.tailwind.css` — Tailwind entry point
- `spec/` — RSpec tests (models, requests, e2e)

## Patterns & Conventions

### Authentication
- Devise is configured on the `User` model
- Use `before_action :authenticate_user!` in controllers requiring auth
- Devise helpers available in specs via `rails_helper.rb` config
- Sign in during request specs: `sign_in(user)` (from Devise::Test::IntegrationHelpers)

### Views & Styling
- Use Tailwind CSS v4 utility classes
- Tailwind config is `@import "tailwindcss"` in `app/assets/stylesheets/application.tailwind.css`
- Layout in `app/views/layouts/application.html.erb`
- Use Turbo Frames for partial page updates

### Testing
- RSpec configured in `spec/rails_helper.rb`
- Devise test helpers included for `:controller`, `:request`, and `:system` types
- System specs use Capybara + Selenium
- Use `let` and `before` blocks, create test records inline

### Routes
- Root: `root "dashboard#show"`
- Devise: `devise_for :users`
- Setup: `get/patch "setup"`

### Database
- PostgreSQL with standard Rails migrations
- Tables: `users` (Devise defaults)

## App Rename Feature

The `/setup` page lets you rename the app. `AppRenameService` updates:
- `config/application.rb` (Ruby module name)
- `config/database.yml` (database names)
- `config/deploy.yml` (Kamal service/image/volume)
- `Dockerfile` (image name comments)
- `app/views/layouts/application.html.erb` (page title)
- `app/views/pwa/manifest.json.erb` (PWA name)
- PostgreSQL databases (rename via ALTER DATABASE)

## Gotchas

- Tailwind v4 uses `@import "tailwindcss"` not `@tailwind base/components/utilities`
- Propshaft (not Sprockets) — no `require` directives in manifests
- esbuild output goes to `app/assets/builds/` — don't edit files there directly
- After app rename, restart the server for the new module name to load
