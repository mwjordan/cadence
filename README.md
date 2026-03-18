# Rails App Starter Kit

A ready-to-go Rails 8 starter template with authentication, testing, and Tailwind CSS pre-configured. Clone it, rename it, and start building.

## What's Included

- **Rails 8.1** with PostgreSQL
- **Devise** authentication (sign up, sign in, sign out, password reset)
- **Tailwind CSS v4** via cssbundling-rails
- **Hotwire** (Turbo + Stimulus)
- **RSpec** with Capybara + Selenium for E2E tests
- **esbuild** for JavaScript bundling
- **Propshaft** asset pipeline
- **Kamal** deployment config
- **Docker** ready

## Quick Start

```bash
# Clone and enter the directory
git clone <repo-url> my_app
cd my_app

# Install dependencies
bundle install
yarn install

# Create and migrate the database
bin/rails db:create db:migrate db:seed

# Start the dev server
bin/dev
```

Visit `http://localhost:3000` and sign in with the seed user:
- **Email:** test@example.com
- **Password:** password123

## Rename Your App

1. Start the server with `bin/dev`
2. Sign in and visit `/setup`
3. Enter your new app name and click **Rename App**
4. Restart the server

This updates the Ruby module, database names, Docker config, page titles, and PWA manifest.

Alternatively, do a manual find-and-replace:
- `RailsAppStarterKit` → `YourAppName` (Ruby module)
- `rails_app_starter_kit` → `your_app_name` (database/config)
- `Rails App Starter Kit` → `Your App Name` (display name)

## Commands

```bash
bin/dev                           # Start dev server (Rails + esbuild + Tailwind)
bundle exec rspec                 # Run all specs
bundle exec rspec spec/models/    # Run model specs
bundle exec rspec spec/e2e/       # Run E2E system specs
bundle exec rubocop               # Lint Ruby code
bin/rails db:migrate              # Run migrations
bin/rails db:seed                 # Seed default user
```

## Project Structure

```
app/
  controllers/     # Rails controllers (use before_action :authenticate_user!)
  models/          # ActiveRecord models (User with Devise)
  views/           # ERB templates (Tailwind-styled)
    devise/        # Customized Devise views
    dashboard/     # Main dashboard
    setup/         # App rename UI
  javascript/
    controllers/   # Stimulus controllers
  services/        # Service objects (AppRenameService)
config/
  routes.rb        # Routes (Devise + dashboard + setup)
  database.yml     # PostgreSQL config
spec/
  models/          # Model specs
  requests/        # Request specs
  e2e/             # System/E2E specs (Capybara + Selenium)
```

## Tech Details

- **Authentication:** Devise on User model. Use `before_action :authenticate_user!` in controllers.
- **Styling:** Tailwind CSS v4 with `@import "tailwindcss"` in `app/assets/stylesheets/application.tailwind.css`
- **JavaScript:** Stimulus controllers in `app/javascript/controllers/`, auto-registered via `index.js`
- **Testing:** RSpec + Devise test helpers included for `:request` and `:system` spec types
- **Asset pipeline:** Propshaft (not Sprockets) — no `require` directives in manifests
